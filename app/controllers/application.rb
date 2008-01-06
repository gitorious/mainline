# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  session :session_key => '_ks1_session_id', :secret => GitoriousConfig["cookie_secret"]
  include AuthenticatedSystem
  include ExceptionNotifiable
  
  rescue_from(ActiveRecord::RecordNotFound) do |e| 
    render :file => "#{RAILS_ROOT}/public/404.html"
  end
  
  protected
    def require_user_has_ssh_keys
      unless current_user.ssh_keys.count > 0
        flash[:error] = "You need to upload your public key first"
        redirect_to new_account_key_path
        return 
      end
    end
end
