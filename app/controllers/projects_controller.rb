class ProjectsController < ApplicationController
  before_filter :login_required, :only => [:create, :update, :destroy, :new]
  
  def index
    @projects = Project.find(:all)
  end
  
  def show
    @project = Project.find(params[:id])
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
  
  def update
    @project = Project.find(params[:id])
    @project.attributes = params[:project]
    if @project.save
      redirect_to project_path(@project)
    else
      render :action => 'new'
    end
  end
  
  def destroy
    @project = Project.find(params[:id])
    if @project.destroy
      redirect_to projects_path
    else
      flash[:error]
    end
  end
end