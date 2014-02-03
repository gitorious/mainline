# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
require "gitorious/view/form_builder"
require "wiki_controller"

class PagesController < WikiController
  before_filter :login_required, :except => [:index, :show, :git_access]
  before_filter :find_project
  before_filter :check_if_wiki_enabled
  before_filter :assert_readyness
  before_filter :require_write_permissions, :only => [:edit, :update]
  renders_in_site_specific_context

  def index
    render_index(
      ProjectPresenter.new(@project),
      @project.wiki_repository.git,
      project_pages_path(:format => :atom))
  end

  def show
    format = default_format? ? Page::DEFAULT_FORMAT : params[:format]
    page = Page.find(params[:id], @project.wiki_repository.git, format)
    render_show(ProjectPresenter.new(@project), page)
  end

  def edit
    page = Page.find(params[:id], @project.wiki_repository.git)
    render_edit(ProjectPresenter.new(@project), page)
  end

  def update
    @page = Page.find(params[:id], @project.wiki_repository.git)
    @page.user = current_user

    if @page.content == params[:page][:content]
      flash[:error] = I18n.t("pages_controller.no_changes")
      render_edit(ProjectPresenter.new(@project), @page) and return
    end

    @page.content = params[:page][:content]
    if @page.save
      if @project.new_event_required?(Action::UPDATE_WIKI_PAGE, @project, current_user, @page.title)
        @project.create_event(Action::UPDATE_WIKI_PAGE, @project, current_user, @page.title)
      end
      redirect_to project_page_path(@project, @page)
    else
      flash[:error] = I18n.t("pages_controller.invalid_page_error")
      render_edit(ProjectPresenter.new(@project), @page)
    end
  end

  def history
    page = Page.find(params[:id], @project.wiki_repository.git)
    render_page_history(ProjectPresenter.new(@project), @project.wiki_repository, page)
  end

  def git_access
    render_git_access(ProjectPresenter.new(@project), @project.wiki_repository)
  end

  protected
  def assert_readyness
    unless @project.wiki_repository.ready?
      flash[:notice] = I18n.t("pages_controller.repository_not_ready")
      redirect_to project_path(@project) and return
    end
  end

  def check_if_wiki_enabled
    unless @project.wiki_enabled?
      redirect_to project_path(@project) and return
    end
  end

  def require_write_permissions
    unless can_push?(current_user, @project.wiki_repository)
      flash[:error] = "This project has restricted wiki editing to project members"
      redirect_to project_pages_path(@project)
    end
  end

  # Helpers
  def show_writable_wiki_url?(wiki, user)
    !user.nil? && can_push?(user, wiki)
  end

  def wiki_index_path(project, format = nil)
    project_pages_path(project, format)
  end

  def wiki_index_url(project, format = nil)
    Gitorious.url(wiki_index_path(project, format))
  end

  def wiki_page_path(project, page)
    project_page_path(project, page)
  end

  def wiki_git_access_path(project)
    git_access_project_pages_path(project)
  end

  def edit_wiki_page_path(project, page)
    edit_project_page_path(project, page)
  end

  def page_history_path(project, page, format = nil)
    history_project_page_path(project, page, format)
  end
end
