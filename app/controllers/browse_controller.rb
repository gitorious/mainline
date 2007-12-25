class BrowseController < ApplicationController
  before_filter :find_project_and_repository
  
  def index
    @git = Git.bare(@repository.full_repository_path)
  end
  
  def tree
    @git = Git.bare(@repository.full_repository_path)   
    @tree = @git.gtree(params[:sha])
  end
  
  def commit
    @git = Git.bare(@repository.full_repository_path)
    @commit = @git.gcommit(params[:sha])
  end
  
  def diff
    @git = Git.bare(@repository.full_repository_path)
    @diff = @git.diff(params[:sha], params[:other_sha])
  end
  
  def blob
    @git = Git.bare(@repository.full_repository_path)
    @blob = @git.gblob(params[:sha])
  end
  
  def log
    @git = Git.bare(@repository.full_repository_path)
    # TODO: paginated logs
  end
  
  def archive
    # TODO
  end
  
  protected
    def find_project_and_repository
      @project = Project.find_by_slug!(params[:project_id])
      @repository = @project.repositories.find_by_name!(params[:repository_id])
    end
end
