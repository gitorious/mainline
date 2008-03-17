class LogsController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
    
  def index
    redirect_to project_repository_log_path(@project, @repository, @repository.head_candidate.name)
  end
  
  def show
    @git = @repository.git
    @commits = @repository.paginated_commits(params[:id], params[:page])
    # TODO: refactor this
    @atom_auto_discovery_url = formatted_project_repository_log_path(@project, @repository, "master", :atom)
    respond_to do |format|
      format.html
      format.atom
    end
  end
  
end
