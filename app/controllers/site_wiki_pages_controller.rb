# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
require "wiki_controller"

class SiteWikiPagesController < WikiController
  before_filter :login_required, :except => [:index, :show, :git_access, :repository_config, :writable_by]
  before_filter :require_site_admin, :only => [:edit, :update]
  renders_in_site_specific_context
  helper PagesHelper, SiteWikiPagesHelper

  def index
    site = current_site
    nodes = tree_nodes(site.wiki)
    redirect_to(:action => "edit", :id => "Home") and return if nodes.count == 0
    render_index(site, site.wiki, site_wiki_pages_path(:format => :atom))
  end

  def show
    site = current_site
    render_show(site, page(site))
  end

  def edit
    site = current_site
    render_edit(site, page(site))
  end

  def update
    @site = current_site
    @page = page(@site)
    @page.user = current_user

    if @page.content == params[:page][:content]
      flash[:error] = I18n.t("pages_controller.no_changes")
      render :action => "edit" and return
    end

    @page.content = params[:page][:content]
    if @page.save
      redirect_to site_wiki_page_path(@page)
    else
      flash[:error] = I18n.t("pages_controller.invalid_page_error")
      render :action => "edit"
    end
  end

  def history
    site = current_site
    render_page_history(site, site.wiki, page(site))
  end

  def git_access
    site = current_site
    render_git_access(site, site)
  end

  # Used internally by Gitorious
  def repository_config
    site = Site.find_by_id(params[:site_id])
    gitdir = site.wiki_repo_name
    config_data = "real_path:#{gitdir}\n"
    config_data << "force_pushing_denied:true"
    headers["Cache-Control"] = "public, max-age=600"
    render :text => config_data, :content_type => "text/x-yaml"
  end

  # Used internally to check write permissions by gitorious
  # Site wikis are always writable as long as user a valid acct/key
  def writable_by
    render :text => "true" and return
  end

  protected
  def assert_readyness
    unless current_site.ready?
      flash[:notice] = I18n.t("pages_controller.repository_not_ready")
      redirect_to "/" and return
    end
  end

  def require_site_admin
    unless site_admin?(current_user)
      flash[:error] = I18n.t "admin.users_controller.check_admin"
      redirect_to site_wiki_pages_path
    end
  end

  def page(site)
    @page ||= Page.find(params[:id], site.wiki)
  end

  # Helpers
  helper_method :site_page_path

  def site_page_path(*args)
    site_wiki_page_path(*args[1..-1])
  end

  def show_writable_wiki_url?(wiki, user)
    !user.nil?
  end

  def wiki_index_path(site, format = nil)
    site_wiki_pages_path(format)
  end

  def wiki_page_path(site, page)
    site_wiki_page_path(page)
  end

  def wiki_git_access_path(site)
    git_access_site_wiki_pages_path
  end

  def edit_wiki_page_path(site, page)
    edit_site_wiki_page_path(page)
  end

  def page_history_path(site, page, format = nil)
    history_site_wiki_page_path(page, format)
  end
end
