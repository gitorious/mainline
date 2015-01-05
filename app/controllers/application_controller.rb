# encoding: utf-8
#--
#   Copyright (C) 2011-2013 Gitorious AS
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
require "gitorious"
require "gitorious/view"
require "gitorious/view/site_helper"
require "open_id_authentication"
require "gitorious/view/ui_helper"

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include RoutingHelper
  include Gitorious::Authorization
  include Gitorious::View::SiteHelper
  include Gitorious::View::UIHelper
  protect_from_forgery

  before_filter :public_and_logged_in
  before_filter :require_current_eula

  after_filter :mark_flash_status

  rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
  rescue_from ActionController::UnknownController, :with => :render_not_found
  rescue_from ::AbstractController::ActionNotFound, :with => :render_not_found
  rescue_from Grit::GitRuby::Repository::NoSuchPath, :with => :render_not_found
  rescue_from Grit::Git::GitTimeout, :with => :render_git_timeout
  rescue_from RecordThrottling::LimitReachedError, :with => :render_throttled_record
  rescue_from Gitorious::Authorization::UnauthorizedError, :with => :render_unauthorized
  rescue_from(UnexpectedSiteContext) { |site| redirect_to(site.target) }

  def rescue_action(exception)
    return super if !Rails.env.production?

    case exception
      # Can't catch RoutingError with rescue_from it seems,
      # so do it the old-fashioned way
    when ActionController::RoutingError
      render_not_found
    else
      super
    end
  end

  def handle_missing_sha
    flash[:error] = "No such SHA1 was found"
    redirect_to(project_repository_commits_path(@project, @repository))
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
    unless current_user.ssh_keys.count > 0 || Gitorious.ssh_daemon.nil?
      flash[:error] = I18n.t "application.require_ssh_keys_error"
      redirect_to new_user_key_path(current_user)
      return
    end
  end

  def require_current_user
    current_user_only_redirect unless @user == current_user
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
      set_containing_project
    elsif params[:group_id]
      @owner = Group.find_by_name!(params[:group_id])
      set_containing_project
    elsif params[:project_id]
      @owner = Project.find_by_slug!(params[:project_id])
      @project = authorize_access_to(@owner)
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def set_containing_project
    if params[:project_id]
      project = Project.find_by_slug!(params[:project_id])
      @containing_project = authorize_access_to(project)
    end
  end

  def find_repository_owner_and_repository
    find_repository_owner
    @owner.repositories.find_by_name!(params[:id])
  end

  def authorize_access_to(thing)
    return thing if !Gitorious.private_repositories?
    authorize_access_with_private_repositories_enabled(thing)
  end

  def authorize_access_with_private_repositories_enabled(thing)
    return thing if can_read?(current_user, thing)
    raise Gitorious::Authorization::UnauthorizedError.new(request.fullpath)
  end

  def find_project
    @project = authorize_access_to(Project.find_by_slug!(params[:project_id]))
  end

  def find_project_and_repository
    @project = authorize_access_to(Project.find_by_slug!(params[:project_id]))
    # We want to look in all repositories that's somehow within this project
    # realm, not just @project.repositories
    r = Repository.find_by_name_and_project_id!(params[:repository_id], @project.id)
    @repository = authorize_access_to(r)
  end

  def check_repository_for_commits
    unless @repository.has_commits?
      flash[:notice] = I18n.t "application.no_commits_notice"
      redirect_to project_repository_path(@project, @repository) and return
    end
  end

  def render_not_found
    render({ :file => Rails.root + "public/404.html",
             :status => 404,
             :layout => false })
  end

  def render_git_timeout
    layout = (request.xhr? ? false : "application")
    render(:file => 'shared/_git_timeout.erb.html', :layout => layout, :format => 'html')
    return false
  end

  def render_throttled_record
    render("/shared/_throttled_record",
           :layout => "application", :status => 412) # precondition failed
    return false
  end

  def render_unauthorized
    render("/shared/_unauthorized",
           :layout => "application", :status => 403) # forbidden
    return false
  end

  def public_and_logged_in
    login_required unless Gitorious.public?
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

  # Hook for Gitorious::View::SiteHelper#find_current_site
  def current_project
    @project
  end

  def redirect_to_current_site_subdomain
    verify_site_context!
  end

  def require_global_site_context
    unless subdomain_without_common.blank?
      redirect_to_top_domain
    end
  end

  def redirect_to_top_domain
    host_without_subdomain = {
      :only_path => false,
      :host => Gitorious.host
    }
    host_without_subdomain[:port] = request.port
    redirect_to host_without_subdomain
  end

  def self.skip_session(options = {})
    return if !Gitorious.public?
    always_skip_session(options)
  end

  def self.always_skip_session(options = {})
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
  #         Group.paginate(:page => params[:page])
  #       end
  #     end
  #
  def paginate(redirect_options = {}, &block)
    begin
      items = yield || []
    rescue WillPaginate::InvalidPage
      items = []
    end

    if params.key?(:page) && items.length == 0
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
    request.headers["X-PJAX"]
  end

  def redirect_to_ref(ref, repo_view, options={:status => 302})
    redirect_to(send(repo_view, @project, @repository, ref), options)
  end

  def get_head(ref)
    if h = @git.get_head(ref)
      return h
    end

    begin
      if commit = @git.commit(@ref)
        return Grit::Head.new(commit.id_abbrev, @git, commit.id)
      end
    rescue Errno::EISDIR
    end

    nil
  end

  def handle_unknown_ref(ref, git, repo_view)
    flash[:error] = "\"#{CGI.escapeHTML(ref)}\" was not a valid ref, trying #{CGI.escapeHTML(git.head.name)} instead"
    redirect_to_ref(git.head.name, repo_view)
  end

  def authorized_filter
    Gitorious::AuthorizedFilter.new(current_user)
  end
  extend Forwardable
  def_delegators :authorized_filter, :filter, :filter_paginated

  helper_method :unshifted_polymorphic_path

  def current_user_only_redirect
    flash[:error] = I18n.t("application.require_current_user", :title => current_user.title)
    redirect_to(user_path(current_user))
  end

  def pre_condition_failed(outcome, &block)
    outcome.pre_condition_failed do |f|
      f.when(:user_required) { |c| redirect_to(login_path) }
      f.when(:rate_limiting) { |c| render_throttled_record }
      f.when(:authorization_required) { |c| render_unauthorized }
      f.when(:owner_required) { |c| render_unauthorized }
      f.when(:current_user_required) { |c| current_user_only_redirect }
      block.call(f) if !block.nil?
    end
  end
end
