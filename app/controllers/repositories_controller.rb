class RepositoriesController < ApplicationController
  before_filter :login_required, :only => [:new, :create]
  before_filter :find_project, 
    :only => [:show, :new, :create, :edit, :update]
    
  def show
    @project.repositories.find(params[:id])
  end
  
  def new
    @repository = @project.repositories.new
  end
  
  def create
    @repository = @project.repositories.new(params[:repository])
    @repository.user = current_user
    if @repository.save
      redirect_to project_repository_path(@project, @repository)
    end
  end
  
  private
    def find_project
      @project = Project.find(params[:project_id])
    end
end
