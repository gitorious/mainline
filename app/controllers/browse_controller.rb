class BrowseController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_for_commits
  
  def index
    @git = Git.bare(@repository.full_repository_path)
    @commits = @git.log(30)
    @tags_per_sha = returning({}) do |hash|
      @git.tags.each do |tag| 
        hash[tag.sha] ||= []
        hash[tag.sha] << tag.name 
      end
    end
  end
  
  def tree
    @git = Git.bare(@repository.full_repository_path)   
    @tree = @git.gtree(params[:sha])
  end
  
  def commit
    @git = Git.bare(@repository.full_repository_path)
    @commit = @git.gcommit(params[:sha])
    @diff = @git.diff(@commit.parent.sha, @commit.sha)
  end
  
  def diff
    @git = Git.bare(@repository.full_repository_path)
    @diff = @git.diff(params[:sha], params[:other_sha])
  end
  
  def blob
    @git = Git.bare(@repository.full_repository_path)
    @blob = @git.gblob(params[:sha])
  end
  
  def raw
    @git = Git.bare(@repository.full_repository_path)
    @blob = @git.gblob(params[:sha])
    render :text => @blob.contents, :content_type => "text/plain"
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
    
    def check_for_commits
      unless @repository.has_commits?
        flash[:notice] = "The repository doesn't have any commits yet"
        redirect_to project_repository_path(@project, @repository) and return
      end
    end
end
