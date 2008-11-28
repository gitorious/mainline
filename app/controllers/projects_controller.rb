#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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
  before_filter :login_required, :only => [:create, :update, :destroy, :new]
  before_filter :require_user_has_ssh_keys, :only => [:new, :create]
  
  def index
    @projects = Project.paginate(:all, :order => "projects.created_at desc", 
                  :page => params[:page], :include => [:tags, { :repositories => :project } ])
    
    @atom_auto_discovery_url = formatted_projects_path(:atom)
    respond_to do |format|
      format.html { @tags = Project.top_tags }
      format.xml  { render :xml => @projects }
      format.atom { }
    end
  end
  
  def category
    tags = params[:id].to_s.gsub(/,\ ?/, " ")
    @projects = Project.paginate_by_tag(tags, :order => 'created_at desc', 
                  :page => params[:page])
    @atom_auto_discovery_url = formatted_projects_category_path(params[:id], :atom)
    respond_to do |format|
      format.html do
        @tags = Project.tag_counts
        render :action => "index"
      end
      format.xml  { render :xml => @projects }
      format.atom { render :action => "index"}
    end
  end
  
  def show
    @project = Project.find_by_slug!(params[:id], :include => [:repositories])
    @mainline_repository = @project.mainline_repository
    @repositories = @project.repository_clones
    @events = @project.events.paginate(:all, :page => params[:page], 
      :order => "created_at desc", :include => [:user, :project])
    @atom_auto_discovery_url = formatted_project_path(@project, :atom)
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @project }
      format.atom { }
    end
  end
  
  def new
  end
  
  def create
    @project = Project.new(params[:project])
    @project.user = current_user
    if @project.save
      @project.create_event(Action::CREATE_PROJECT, @project, current_user)
      redirect_to projects_path
    else
      render :action => 'new'
    end
  end
  
  def edit
    @project = Project.find_by_slug!(params[:id])
  end
  
  def update
    @project = Project.find_by_slug!(params[:id])
    if @project.user != current_user
      flash[:error] = "You're not the owner of this project"
      redirect_to(project_path(@project)) and return
    end
    @project.attributes = params[:project]
    if @project.save
      @project.create_event(Action::UPDATE_PROJECT, @project, current_user)
      redirect_to project_path(@project)
    else
      render :action => 'new'
    end
  end
  
  def confirm_delete
    @project = Project.find_by_slug!(params[:id])
  end
  
  def destroy
    @project = Project.find_by_slug!(params[:id])
    if @project.can_be_deleted_by?(current_user)
      project_title = @project.title
      @project.destroy
#       Event.create(:action => Action::DELETE_PROJECT, :user => current_user, :data => project_title) # FIXME: project_id cannot be null
    else
      flash[:error] = "You're not the owner of this project, or the project has clones"
    end
    redirect_to projects_path
  end
end