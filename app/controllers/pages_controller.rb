# encoding: utf-8
#--
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

class PagesController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :git_access]
  before_filter :find_project
  before_filter :check_if_wiki_enabled
  before_filter :assert_readyness
  before_filter :require_write_permissions, :only => [:edit, :update]
  renders_in_site_specific_context
  
  def index
    respond_to do |format|
      format.html do
        @tree_nodes = @project.wiki_repository.git.tree.contents.select{|n|
          n.name =~ /\.#{Page::DEFAULT_FORMAT}$/
        }
        @root = Breadcrumb::Wiki.new(@project)
        @atom_auto_discovery_url = project_pages_path(:format => :atom)
      end
      format.atom do
        @commits = @project.wiki_repository.git.commits("master", 30)
        expires_in 30.minutes
      end
    end
  end
  
  def show
    @atom_auto_discovery_url = project_pages_path(:format => :atom)
    @page, @root = page_and_root
    if @page.new?
      if logged_in?
        redirect_to edit_project_page_path(@project, params[:id]) and return
      else
        render "no_page" and return
      end
    end
  end
  
  def edit
    @page, @root = page_and_root
    @page.user = current_user
  end
  
  def preview
    @page, @root = page_and_root
    @page.content = params[:page][:content]
    respond_to do |wants|
      wants.js
    end
  end
  
  def update
    @page = Page.find(params[:id], @project.wiki_repository.git)
    @page.user = current_user
    
    if @page.content == params[:page][:content]
      flash[:error] = I18n.t("pages_controller.no_changes")
      render :action => "edit" and return
    end

    @page.content = params[:page][:content]
    if @page.save
      if @project.new_event_required?(Action::UPDATE_WIKI_PAGE, @project, current_user, @page.title)
        @project.create_event(Action::UPDATE_WIKI_PAGE, @project, current_user, @page.title) 
      end
      redirect_to project_page_path(@project, @page)
    else
      flash[:error] = I18n.t("pages_controller.invalid_page_error")
      render :action => "edit"
    end
  end
  
  def history
    @page, @root = page_and_root
    if @page.new?
      redirect_to edit_project_page_path(@project, @page) and return
    end
    
    @commits = @page.history(30)
    @user_and_email_map = @project.wiki_repository.users_by_commits(@commits)
  end

  def git_access
    @root = Breadcrumb::Wiki.new(@project)
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
    
    def page_and_root
      page = Page.find(params[:id], @project.wiki_repository.git)    
      root = Breadcrumb::Page.new(page, @project)
      return page, root
    end
    
    def require_write_permissions
      unless @project.wiki_repository.writable_by?(current_user)
        flash[:error] = "This project has restricted wiki editing to project members"
        redirect_to project_pages_path(@project)
      end
    end
end
