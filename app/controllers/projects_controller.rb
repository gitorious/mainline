class ProjectsController < ApplicationController
  before_filter :login_required, :only => [:create, :update, :destroy, :new]
  
  def index
    @projects = Project.paginate(:all, :order => "created_at desc", 
                  :page => params[:page])
  end
  
  def show
    @project = Project.find_by_slug!(params[:id])
    @repositories = @project.repositories
  end
  
  def new
  end
  
  def create
    @project = Project.new(params[:project])
    @project.user = current_user
    if @project.save
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
    @project.attributes = params[:project]
    if @project.save
      redirect_to project_path(@project)
    else
      render :action => 'new'
    end
  end
  
  def destroy
    @project = Project.find_by_slug!(params[:id])
    @project.destroy
    redirect_to projects_path
  end
end