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
    # TODO: Patch rails to keep track of what it responds to so we can DRY this up
    @atom_auto_discovery_url = project_repository_formatted_browse_path(@project, @repository, :atom)
    respond_to do |format|
      format.html
      format.atom
    end
  end
  
  def tree
    @git = Git.bare(@repository.full_repository_path)   
    @tree = @git.gtree(params[:sha])
  end
  
  def commit
    @diffmode = params[:diffmode] == "sidebyside" ? "sidebyside" : "inline"
    @git = Git.bare(@repository.full_repository_path)
    @commit = @git.gcommit(params[:sha])
    if @commit.parent
      @diff = @git.diff(@commit.parent.sha || "", @commit.sha)
    else
      # initial commit
      @diff = @commit.diff("") # fIXME: diffs are the wrong way
    end
    @comment_count = @repository.comments.count(:all, :conditions => {:sha1 => @commit.sha})
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
  
  @@per_page = 30
  
  def log
    @git = Git.bare(@repository.full_repository_path)
    skip = params[:page].blank? ? 0 : (params[:page].to_i-1) * @@per_page
    @commits = @git.log(30, skip)
    @tags_per_sha = returning({}) do |hash|
      @git.tags.each do |tag| 
        hash[tag.sha] ||= []
        hash[tag.sha] << tag.name 
      end
    end
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
