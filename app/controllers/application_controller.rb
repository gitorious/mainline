# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
  include RoutingHelper
  protect_from_forgery

  before_filter :public_and_logged_in
  before_filter :require_current_eula

  include SslRequirement # Need to be included after the above

  after_filter :mark_flash_status

  filter_parameter_logging :password, :password_confirmation

  layout :pick_layout_based_on_site

  rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
  rescue_from ActionController::UnknownController, :with => :render_not_found
  rescue_from ActionController::UnknownAction, :with => :render_not_found
  rescue_from Grit::GitRuby::Repository::NoSuchPath, :with => :render_not_found
  rescue_from Grit::Git::GitTimeout, :with => :render_git_timeout
  rescue_from RecordThrottling::LimitReachedError, :with => :render_throttled_record

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

  def require_not_logged_in
    redirect_to root_path if logged_in?
  end

  def require_current_eula
    if logged_in?
      unless current_user.terms_accepted?
        store_location
        flash[:error] = I18n.t "views.license.terms_not_accepted"
        redirect_to user_license_path(current_user)
        return
      end
    end
    return true
  end

  def find_repository_owner
    if params[:user_id]
      @owner = User.find_by_login!(params[:user_id])
      @containing_project = Project.find_by_slug!(params[:project_id]) if params[:project_id]
    elsif params[:group_id]
      @owner = Group.find_by_name!(params[:group_id])
      @containing_project = Project.find_by_slug!(params[:project_id]) if params[:project_id]
    elsif params[:project_id]
      @owner = Project.find_by_slug!(params[:project_id])
      @project = @owner
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
    render :template => "#{RAILS_ROOT}/public/404.html", :status => 404, :layout => "application"
  end

  def render_git_timeout
    render :partial => "/shared/git_timeout", :layout => (request.xhr? ? false : "application") and return
  end

  def render_throttled_record
    render :partial => "/shared/throttled_record",
    :layout => "application", :status => 412 # precondition failed
    return false
  end

  def public_and_logged_in
    login_required unless GitoriousConfig['public_mode']
  end

  def mark_flash_status
    unless flash.empty?
      headers['X-Has-Flash'] = "true"
    end
  end

  # Returns an array like [branch_ref, *tree_path]
  def branch_with_tree(branch_ref, tree_path)
    tree_path = tree_path.is_a?(Array) ? tree_path : ensplat_path(tree_path)
    ensplat_path(branch_ref) + tree_path
  end
  helper_method :branch_with_tree

  def branch_and_path(branch_and_path, git)
    branch_and_path = desplat_path(branch_and_path)
    branch_ref = path = nil
    tags = Array(git.tags).map{|t| t.name }.sort{|a,b| b.length <=> a.length }
    tags.each do |tag|
      if "#{branch_and_path}/".starts_with?("#{tag}/")
        branch_ref = tag
        path = ensplat_path(branch_and_path.sub(tag, "")) || []
        break
      end
    end
    unless path
      heads = Array(git.heads).map{|h| h.name }.sort{|a,b| b.length <=> a.length }
      heads.each do |head|
        if "#{branch_and_path}/".starts_with?("#{head}/")
          branch_ref = head
          path = ensplat_path(branch_and_path.sub(head, "")) || []
          break
        end
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
        url_parameters = {:only_path => false, :host => "#{current_site.subdomain}.#{GitoriousConfig["gitorious_host"]}#{request.port_string}"}.merge(params)
        redirect_to url_parameters
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

  def self.skip_session(options = {})
    skip_before_filter :public_and_logged_in, options
    skip_before_filter :require_current_eula, options
    skip_after_filter :mark_flash_status, options
    prepend_before_filter :skip_session_expiry, options
  end

  def skip_session_expiry
    request.session_options[:expire_after] = nil
  end

  def cache_forever
    cache_for(315360000.seconds)
  end

  def cache_for(seconds)
    expires_in(seconds, :public => true)
  end

  # A wrapper around ActionPack's #stale?, that always returns true
  # if there's data in the flash hash or if we're in development mode
  def stale_conditional?(etag, last_modified)
    return true if !flash.empty? || Rails.env == "development"
    stale?(:etag => [etag, current_user], :last_modified => last_modified)
  end

  private
  # "Safely" check whether or not we're using the session. Unfortunately
  # simply touching the session object will prompt Rails to issue a session
  # cookie in the response, which in some cases breaks caching.
  #
  # Use this method as a guard in actions where cacheability is important,
  # and you most probably don't need to access the session.
  def using_session?
    !request.session_options[:expire_after].nil?
  end

  def ssl_allowed?
    request.ssl?
  end

  def ssl_required?
    GitoriousConfig["use_ssl"] && using_session? && logged_in?
  end

  def unshifted_polymorphic_path(repo, path_spec)
    if path_spec[0].is_a?(Symbol)
      path_spec.insert(1, repo.owner)
    else
      path_spec.unshift(repo.owner)
    end
  end

  # "Transactional wrapper" for pagination. Wrap calls to Model.paginate in a
  # call to this method to have "page out of bounds" errors handled seemlessly.
  #
  # paginate expects its block argument to return a collection of objects to
  # be paginated. If the returned collection is nil, or has 0 entries, it is
  # considered a pagination error _if_ the :page parameter was provided.
  #
  # Pagination errors are handled by setting flash[:error] and redirecting
  # back to the original page, as specified by the +redirect_options+ argument.
  #
  # The flash[:error] entry is set by looking up the i18n string for
  # <controller>_controller.<action>_pagination_oob (oob = "out of bounds").
  #
  # The method returns whatever is returned by its block argument. Typical
  # usage:
  #
  #     def index
  #       @groups = paginate(:action => "index") do
  #         Group.paginate(:all, :page => params[:page])
  #       end
  #     end
  #
  def paginate(redirect_options = {}, &block)
    begin
      items = yield || []
    rescue WillPaginate::InvalidPage
      items = []
    end

    if params.key?(:page) && items.count == 0
      controller = params[:controller].gsub("/", "_")
      key = "#{controller}_controller.#{params[:action]}_pagination_oob"
      flash[:error] = I18n.t(key, :page => params[:page].to_i)
      redirect_to(redirect_options)
    end

    items
  end

  def page_free_redirect_options
    redirect_options = params.dup
    redirect_options.delete(:page)
    redirect_options
  end

  def pjax_request?
    request.headers['X-PJAX']
  end

  def redirect_to_ref(ref, repo_view)
    redirect_to repo_owner_path(@repository, repo_view, @project, @repository, ref)
  end

  def get_head(ref)
    if h = @git.get_head(ref)
      return h
    end

    begin
      if commit = @git.commit(@ref)
        return Grit::Head.new(commit.id_abbrev, commit)
      end
    rescue Errno::EISDIR => err
    end

    nil
  end

  def handle_unknown_ref(ref, git, repo_view)
    flash[:error] = "\"#{CGI.escapeHTML(ref)}\" was not a valid ref, trying #{CGI.escapeHTML(git.head.name)} instead"
    redirect_to_ref(git.head.name, repo_view)
  end

  helper_method :unshifted_polymorphic_path
end
