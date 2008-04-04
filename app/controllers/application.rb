# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  session :session_key => '_ks1_session_id', :secret => GitoriousConfig["cookie_secret"]
  include AuthenticatedSystem
  include ExceptionNotifiable
  
  rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
  rescue_from ActionController::UnknownController, :with => :render_not_found
  rescue_from ActionController::UnknownAction, :with => :render_not_found
  
  def rescue_action(exception)
    return super if RAILS_ENV != "production"
    
    case exception
      # Can't catch RoutingError with rescue_from it seems, 
      # so do it the old-fashioned way
    when ActionController::RoutingError
      render_not_found
    else
      super
    end
  end
  
  protected
    def require_user_has_ssh_keys
      unless current_user.ssh_keys.count > 0
        flash[:error] = "You need to upload your public key first"
        redirect_to new_account_key_path
        return 
      end
    end
    
    def find_project
      @project = Project.find_by_slug!(params[:project_id])
    end
    
    def find_project_and_repository
      @project = Project.find_by_slug!(params[:project_id])
      @repository = @project.repositories.find_by_name!(params[:repository_id])
    end
    
    def check_repository_for_commits
      unless @repository.has_commits?
        flash[:notice] = "The repository doesn't have any commits yet"
        redirect_to project_repository_path(@project, @repository) and return
      end
    end
    
    def render_not_found
      render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
    end
end
