# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class SiteWikiPagesController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :git_access, :config, :writable_by]
  before_filter :require_site_admin, :only => [:edit, :update]

  renders_in_site_specific_context

  def index
    @site = current_site
    respond_to do |format|
      format.html do
        @root = Breadcrumb::SiteWiki.new(@site.title)
        @tree_nodes = @site.wiki.tree.contents.select{|n|
          n.name =~ /\.#{Page::DEFAULT_FORMAT}$/
        }
        # @root = Breadcrumb::Wiki.new(@project)
        @atom_auto_discovery_url = site_wiki_pages_path(:format => :atom)
      end
      format.atom do
        @commits = @site.wiki.commits("master", 30)
        expires_in 30.minutes
      end
    end
  end
  
  def show
    @site = current_site
    @atom_auto_discovery_url = site_wiki_pages_path(:format => :atom)
    @page, @root = page_and_root
    if @page.new?
      if logged_in?
        redirect_to edit_site_wiki_page_path(params[:id]) and return
      else
        render "no_page" and return
      end
    end
  end
  
  def edit
    @site = current_site
    @atom_auto_discovery_url = site_wiki_pages_path(:format => :atom)
    @page, @root = page_and_root
    @page.user = current_user
  end
  
  def preview
    @site = current_site
    @page, @root = page_and_root
    @page.content = params[:page][:content]
    respond_to do |wants|
      wants.js
    end
  end
  
  def update
    @site = current_site
    @page = Page.find(params[:id], @site.wiki)
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
    @site = current_site
    @page, @root = page_and_root
    if @page.new?
      redirect_to edit_site_wiki_page_path(@page) and return
    end
    
    @commits = @page.history(30)
    @user_and_email_map = Repository.users_by_commits(@commits)
  end

  def git_access
    @site = current_site
    # @root = Breadcrumb::Wiki.new(@project)
  end

  # Used internally by Gitorious 
  def config
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
      unless current_site.repository.ready?
        flash[:notice] = I18n.t("pages_controller.repository_not_ready")
        redirect_to "/" and return
      end
    end
        
  def page_and_root
    page = Page.find(params[:id], @site.wiki)    
    root = Breadcrumb::SiteWikiPage.new(page, @site.title)
    return page, root
  end

  def require_site_admin
    unless current_user.site_admin?
      flash[:error] = I18n.t "admin.users_controller.check_admin"
      redirect_to site_wiki_pages_path
    end
  end
  
end
