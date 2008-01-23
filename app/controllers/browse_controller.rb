class BrowseController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_for_commits
  
  LOGS_PER_PAGE = 30
  
  def index
    @git = Gitorious::Gitto.new(@repository.full_repository_path)
    @commits = @git.log(LOGS_PER_PAGE)
    @tags_per_sha = @git.tags_by_sha
    # TODO: Patch rails to keep track of what it responds to so we can DRY this up
    @atom_auto_discovery_url = project_repository_formatted_browse_path(@project, @repository, :atom)
    respond_to do |format|
      format.html
      format.atom
    end
  end
  
  def tree
    @git = Gitorious::Gitto.new(@repository.full_repository_path)   
    @tree = @git.tree(params[:sha])
  end
  
  def commit
    @diffmode = params[:diffmode] == "sidebyside" ? "sidebyside" : "inline"
    @git = Gitorious::Gitto.new(@repository.full_repository_path)
    @commit = @git.commit(params[:sha])
    if @commit.parent
      @diff = @git.diff(@commit.parent.sha || "", @commit.sha)
    else
      # initial commit, link to the initial tree instead
      @diff = nil
    end
    @comment_count = @repository.comments.count(:all, :conditions => {:sha1 => @commit.sha})
  end
  
  def diff
    @git = Gitorious::Gitto.new(@repository.full_repository_path)
    @diff = @git.diff(params[:sha], params[:other_sha])
  end
  
  def blob
    @git = Gitorious::Gitto.new(@repository.full_repository_path)
    @blob = @git.blob(params[:sha])
  end
  
  def raw
    @git = Gitorious::Gitto.new(@repository.full_repository_path)
    @blob = @git.blob(params[:sha])
    render :text => @blob.contents, :content_type => "text/plain"
  end
  
  def log
    @git = Gitorious::Gitto.new(@repository.full_repository_path)
    skip = params[:page].blank? ? 0 : (params[:page].to_i-1) * LOGS_PER_PAGE
    @commits = @git.log(LOGS_PER_PAGE, skip)
    @tags_per_sha = @git.tags_by_sha
    # TODO: Patch rails to keep track of what it responds to so we can DRY this up
    @atom_auto_discovery_url = project_repository_formatted_browse_path(@project, @repository, :atom)
    respond_to do |format|
      format.html
      format.atom
    end
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
