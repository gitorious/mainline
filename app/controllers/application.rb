#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  session :session_key => '_ks1_session_id', :secret => YAML::load_file(File.join(Rails.root, "config/gitorious.yml"))["cookie_secret"]
  include AuthenticatedSystem
  include ExceptionNotifiable
  
  before_filter :public_and_logged_in
  
  rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
  rescue_from ActionController::UnknownController, :with => :render_not_found
  rescue_from ActionController::UnknownAction, :with => :render_not_found
  rescue_from Grit::GitRuby::Repository::NoSuchPath, :with => :render_not_found
  rescue_from Grit::Git::GitTimeout, :with => :render_git_timeout
  
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
        flash[:error] = I18n.t "application.require_ssh_keys_error"
        redirect_to new_account_key_path
        return 
      end
    end
    
    def find_repository_owner
      if params[:project_id]
        @owner = Project.find_by_slug!(params[:project_id])
      elsif params[:user_id]
        @owner = User.find_by_login!(params[:user_id])
      elsif params[:group_id]
        @owner = Group.find_by_name!(params[:group_id])
      else
        raise ActiveRecord::RecordNotFound
      end
      if @owner.is_a?(Project)
        @project = @owner
      end
    end
    
    def find_repository_owner_and_repository
      find_repository_owner
      @owner.repositories.find_by_name!(params[:id])
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
        flash[:notice] = I18n.t "application.no_commits_notice"
        redirect_to project_repository_path(@project, @repository) and return
      end
    end
    
    def render_not_found
      render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
    end
    
    def render_git_timeout
      render :partial => "/projects/git_timeout", :layout => "application" and return
    end
    
    def public_and_logged_in
      login_required unless GitoriousConfig['public_mode']
    end
    
    # turns ["foo", "bar"] route globbing parameters into "foo/bar"
    def desplat_path(*paths)
      paths.join("/")
    end
    helper_method :desplat_path
    
    # turns "foo/bar" into ["foo", "bar"] for route globbing
    def ensplat_path(path)
      path.split("/").select{|p| !p.blank? }
    end
    helper_method :ensplat_path
    
    # Returns an array like [branch_ref, *tree_path]
    def branch_with_tree(branch_ref, tree_path)
      tree_path = tree_path.is_a?(Array) ? tree_path : ensplat_path(tree_path)
      ensplat_path(branch_ref) + tree_path
    end
    helper_method :branch_with_tree
    
    def branch_and_path(branch_and_path, git)
      branch_and_path = desplat_path(branch_and_path)
      branch_ref = path = nil
      heads = Array(git.heads).map{|h| h.name }
      heads.each do |head|
        if branch_and_path.starts_with?(head)
          branch_ref = head
          path = ensplat_path(branch_and_path.sub(head, "")) || []
        end
      end
      unless path # fallback
        path = ensplat_path(branch_and_path)[1..-1]
        branch_ref = ensplat_path(branch_and_path)[0]
      end
      [branch_ref, path]
    end
end
