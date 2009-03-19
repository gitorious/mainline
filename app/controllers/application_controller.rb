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
  include AuthenticatedSystem
  include ExceptionNotifiable
  
  before_filter :public_and_logged_in
  before_filter :require_current_eula
  
  layout :pick_layout_based_on_site
  
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
  
  def current_site
    @current_site || Site.default
  end
  
  protected
    # Sets the before_filters needed to be able to render in a Site specific
    # context. +options+ is the options for the before_filters
    def self.renders_in_site_specific_context(options = {})
      before_filter :find_current_site, options
      before_filter :redirect_to_current_site_subdomain, options
    end
    
    # Sets the before_filters needed to make sure the requests are rendered
    # in the "global" (eg without any Site specific layouts + subdomains).
    # +options+ is the options for the before_filter
    def self.renders_in_global_context(options = {})
      before_filter :require_global_site_context, options
    end
  
    # return the url with the +repo+.owner prefixed if it's a mainline repo,
    # otherwise return the +path_spec+
    # if +path_spec+ is an array (and no +args+ given) it'll use that as the 
    # polymorphic-url-style (eg [@project, @repo, @foo])
    def repo_owner_path(repo, path_spec, *args)
      if repo.team_repo?
        if path_spec.is_a?(Symbol)
          return send("group_#{path_spec}", *args.unshift(repo.owner))
        else
          return *unshifted_polymorphic_path(repo, path_spec)
        end
      elsif repo.user_repo?
        if path_spec.is_a?(Symbol)
          return send("user_#{path_spec}", *args.unshift(repo.owner))
        else
          return *unshifted_polymorphic_path(repo, path_spec)
        end
      else
        if path_spec.is_a?(Symbol)
          return send(path_spec, *args)
        else
          return *path_spec
        end
      end
    end
    helper_method :repo_owner_path
  
    def require_user_has_ssh_keys
      unless current_user.ssh_keys.count > 0
        flash[:error] = I18n.t "application.require_ssh_keys_error"
        redirect_to new_user_key_path(current_user)
        return 
      end
    end

    def require_current_user
      unless @user == current_user
        flash[:error] = I18n.t "application.require_current_user", :title => current_user.title
        redirect_to user_path(current_user)
        return
      end
    end
    
    def require_current_eula
      if logged_in?
        unless current_user.current_license_agreement_accepted?
          store_location
          flash[:error] = I18n.t "views.license.terms_not_accepted"
          redirect_to user_license_path(current_user)
          return
        end
      end
      return true
    end
    
    def find_repository_owner
      if params[:project_id]
        @owner = Project.find_by_slug!(params[:project_id])
        @project = @owner
      elsif params[:user_id]
        @owner = User.find_by_login!(params[:user_id])
      elsif params[:group_id]
        @owner = Group.find_by_name!(params[:group_id])
      else
        raise ActiveRecord::RecordNotFound
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
      # We want to look in all repositories that's somehow within this project
      # realm, not just @project.repositories
      @repository = Repository.find_by_name_and_project_id!(params[:repository_id], @project.id)
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
      paths.flatten.compact.map{|p| CGI.unescape(p) }.join("/")
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
    
    def find_current_site
      @current_site ||= begin
        if @project
          @project.site
        else
          if !subdomain_without_common.blank?
            Site.find_by_subdomain(subdomain_without_common)
          end
        end
      end
    end
    
    def pick_layout_based_on_site
      if current_site && current_site.subdomain
        current_site.subdomain
      else
        "application"
      end
    end
    
    def subdomain_without_common
      tld_length = GitoriousConfig["gitorious_host"].split(".").length - 1
      request.subdomains(tld_length).select{|s| s !~ /^(ww.|secure)$/}.first
    end
    
    def redirect_to_current_site_subdomain
      return unless request.get?
      if !current_site.subdomain.blank?
        if subdomain_without_common != current_site.subdomain
          redirect_to(:only_path => false, 
            :host => "#{current_site.subdomain}.#{GitoriousConfig["gitorious_host"]}#{request.port_string}")
        end
      elsif !subdomain_without_common.blank?
        redirect_to_top_domain
      end
    end
    
    def require_global_site_context
      unless subdomain_without_common.blank?
        redirect_to_top_domain
      end
    end
    
    def redirect_to_top_domain
      host_without_subdomain = {
        :only_path => false, 
        :host => GitoriousConfig["gitorious_host"]
      }
      if ![80, 443].include?(request.port)
        host_without_subdomain[:host] << ":#{request.port}"
      end
      redirect_to host_without_subdomain
    end
    
  private  
    def unshifted_polymorphic_path(repo, path_spec)
      if path_spec[0].is_a?(Symbol)
        path_spec.insert(1, repo.owner)
      else
        path_spec.unshift(repo.owner)
      end
    end
end
