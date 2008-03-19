class LogsController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
    
  def index
    redirect_to project_repository_log_path(@project, @repository, @repository.head_candidate.name)
  end
  
  def show
    @git = @repository.git
    @commits = @repository.paginated_commits(params[:id], params[:page])
    @atom_auto_discovery_url = project_repository_formatted_log_feed_path(@project, @repository, params[:id], :atom)
    respond_to do |format|
      format.html
    end
  end
  
  def feed
    @git = @repository.git
    @commits = @repository.git.commits(params[:id])
    respond_to do |format|
      format.html { redirect_to(project_repository_log_path(@project, @repository, params[:id]))}
      format.atom
    end
  end
  
end
