class CommitsController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  
  def index
    redirect_to project_repository_log_path(@project, @repository, @repository.head_candidate.name)
  end

  def show
    @diffmode = params[:diffmode] == "sidebyside" ? "sidebyside" : "inline"
    @git = @repository.git
    @commit = @git.commit(params[:id])
    @diffs = @commit.diffs
    @comment_count = @repository.comments.count(:all, :conditions => {:sha1 => @commit.id})
    respond_to do |format|
      format.html
      # TODO: format.diff { render :content_type => "text/plain" }
    end
  end
  
end
