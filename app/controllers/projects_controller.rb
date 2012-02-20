# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2008 Cairo Noleto <caironoleto@gmail.com>
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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

class ProjectsController < ApplicationController
  include ProjectFilters

  before_filter :login_required,
    :only => [:create, :update, :destroy, :new, :edit, :confirm_delete]
  before_filter :check_if_only_site_admins_can_create, :only => [:new, :create]
  before_filter :find_project,
    :only => [:show, :clones, :edit, :update, :confirm_delete, :destroy, :edit_slug]
  before_filter :require_admin, :only => [:edit, :update, :edit_slug]
  before_filter :require_user_has_ssh_keys, :only => [:new, :create]
  renders_in_site_specific_context :only => [:show, :edit, :update, :confirm_delete]
  renders_in_global_context :except => [:show, :edit, :update, :confirm_delete, :clones]

  def index
    @projects = paginate(:action => "index") do
      paginate_projects(params[:page] || 1, Project.per_page)
    end

    return if @projects.count == 0 && params.key?(:page)

    @atom_auto_discovery_url = projects_path(:format => :atom)
    respond_to do |format|
      format.html {
        @active_recently = Project.most_active_recently
        @tags = Project.top_tags
      }
      format.xml  { render :xml => @projects }
      format.atom { }
    end
  end

  def show
    @events = paginate(:action => "show", :id => @project.to_param) do
      Rails.cache.fetch("paginated-project-events:#{@project.id}:#{params[:page] || 1}", :expires_in => 10.minutes) do
        events_finder_options = {}
        events_finder_options.merge!(@project.events.top.proxy_options)
        events_finder_options.merge!({:per_page => Event.per_page, :page => params[:page]})
        @project.events.paginate(events_finder_options)
      end
    end

    return if @events.count == 0 && params.key?(:page)
    @big_repos = 10
    @mainlines = by_push_time(@project.repositories.mainlines)
    @owner = @project
    @root = @project
    @group_clones = @project.recently_updated_group_repository_clones
    @user_clones = @project.recently_updated_user_repository_clones
    @atom_auto_discovery_url = project_path(@project, :format => :atom)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @project }
      format.atom { }
    end
  end

  def clones
    @owner = @project
    @group_clones = @project.repositories.by_groups
    @user_clones = @project.repositories.by_users
    respond_to do |format|
      format.js { render :partial => "repositories" }
    end
  end

  def new
    @project = Project.new
    @project.owner = current_user
    @root = Breadcrumb::NewProject.new
  end

  def create
    @project = Project.new(params[:project])
    @root = Breadcrumb::NewProject.new
    @project.user = current_user
    @project.owner = case params[:project][:owner_type]
      when "User"
        current_user
      when "Group"
        current_user.groups.find(params[:project][:owner_id])
      end

    if @project.save
      @project.create_event(Action::CREATE_PROJECT, @project, current_user)
      redirect_to new_project_repository_path(@project)
    else
      render :action => 'new'
    end
  end

  def edit
    @groups = current_user.groups.select{|g| admin?(current_user, g) }
    @root = Breadcrumb::EditProject.new(@project)
  end

  def edit_slug
    @root = Breadcrumb::EditProject.new(@project)
    if request.put?
      @project.slug = params[:project][:slug]
      if @project.save
        @project.create_event(Action::UPDATE_PROJECT, @project, current_user)
        flash[:success] = "Project slug updated"
        redirect_to :action => :show, :id => @project.slug and return
      end
    end
  end

  def update
    @groups = current_user.groups.select{|g| admin?(current_user, g) }
    @root = Breadcrumb::EditProject.new(@project)

    # change group, if requested
    unless params[:project][:owner_id].blank?
      @project.change_owner_to(current_user.groups.find(params[:project][:owner_id]))
    end

    @project.attributes = params[:project]
    changed = @project.changed? # Dirty attr tracking is cleared after #save
    if @project.save && @project.wiki_repository.save
      @project.create_event(Action::UPDATE_PROJECT, @project, current_user) if changed
      flash[:success] = "Project details updated"
      redirect_to project_path(@project)
    else
      render :action => 'edit'
    end
  end

  def preview
    @project = Project.new
    @project.description = params[:project][:description]
    respond_to do |wants|
      wants.js
    end
  end

  def confirm_delete
    @project = Project.find_by_slug!(params[:id])
  end

  def destroy
    if can_delete?(current_user, @project)
      project_title = @project.title
      @project.destroy
    else
      flash[:error] = I18n.t "projects_controller.destroy_error"
    end
    redirect_to projects_path
  end

  protected
  def by_push_time(repositories)
    repositories.sort_by { |ml| ml.last_pushed_at || Time.utc(1970) }.reverse
  end

  def check_if_only_site_admins_can_create
    if GitoriousConfig["only_site_admins_can_create_projects"]
      unless site_admin?(current_user)
        flash[:error] = I18n.t("projects_controller.create_only_for_site_admins")
        redirect_to projects_path
        return false
      end
    end
  end

  def paginate_projects(page, per_page)
    filter_paginated(page, per_page) do |page|
      Project.paginate(:all, :order => "projects.created_at desc",
                       :page => page,
                       :include => [:tags, { :repositories => :project } ])
    end
  end
end
