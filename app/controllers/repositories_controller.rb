class RepositoriesController < ApplicationController
  before_filter :login_required, :except => [:show]
  before_filter :find_project
    
  def show
    @repository = @project.repositories.find(params[:id])
    if @repository.has_commits?
      @recent_commits = Git.bare(@repository.full_repository_path).log(10)
    else
      @recent_commits = []
    end
  end
  
  def new
    # TODO: Add a limit (like 5) per project
    @repository = @project.repositories.new
  end
  
  def create
    @repository = @project.repositories.new(params[:repository])
    @repository.user = current_user
    if @repository.save
      redirect_to project_repository_path(@project, @repository)
    else
      render :action => "new"
    end
  end
  
  def copy
    @repository_to_clone = @project.repositories.find(params[:id])
    @repository = Repository.new_by_cloning(@repository_to_clone)
  end
  
  def create_copy
    @repository_to_clone = @project.repositories.find(params[:id])
    @repository = Repository.new_by_cloning(@repository_to_clone)
    @repository.name = params[:repository][:name]
    @repository.user = current_user
    if @repository.save
      redirect_to project_repository_path(@project, @repository)
    else
      puts @repository.errors.full_messages.inspect
      render :action => :copy
    end
  end
  
  private
    def find_project
      @project = Project.find_by_slug!(params[:project_id])
    end
end
