# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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

class MergeRequestsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :direct_access, :commit_status]
  before_filter :find_repository_owner, :except => [:oauth_return, :direct_access]
  before_filter :find_repository, :except => [:oauth_return, :direct_access]
  before_filter :find_merge_request,
    :except => [:index, :show, :new, :create, :commit_list, :target_branches,
                :oauth_return, :direct_access, :terms_accepted]
  before_filter :assert_merge_request_ownership,
    :except => [:index, :show, :new, :create, :resolve, :commit_list,
                :target_branches, :oauth_return, :direct_access, :commit_status,
                :terms_accepted]
  before_filter :assert_merge_request_resolvable, :only => [:resolve]
  renders_in_site_specific_context

  def index
    @open_merge_requests = paginated_mrs(params[:page], params[:per_page] || 50)
    return if @open_merge_requests.count == 0 && params.key?(:page)

    respond_to do |wants|
      wants.html do
        render(:action => "index", :locals => {
            :repository => RepositoryPresenter.new(@repository),
            :merge_request_statuses => @repository.project.merge_request_statuses,
            :atom_auto_discovery_url => project_repository_merge_requests_path(@project, @repository, :format => :atom),
            :merge_requests => @open_merge_requests,
            :status => params[:status]
          })
      end
      wants.xml  { render :xml => @open_merge_requests.to_xml }
      wants.atom {
        render :file => "merge_requests/index.atom", :locals => {
          :title => "Gitorious: #{@repository.url_path} merge requests",
          :merge_requests => @open_merge_requests
        }
      }
    end
  end

  def commit_list
    @merge_request = @repository.proposed_merge_requests.new(params[:merge_request])
    @merge_request.user = current_user
    @commits = @merge_request.potential_commits
    render :partial => "commit_list", :layout => false
  end

  def commit_status
    @merge_request = authorize_access_to(
      @repository.merge_requests.public.find_by_sequence_number!(params[:id],
                                                                 :include => :target_repository))
    result = @merge_request.commit_merged?(params[:commit_id]) ? "true" : "false"
    render :text => result, :layout => false
  end

  def target_branches
    @merge_request = @repository.proposed_merge_requests.new(params[:merge_request])
    @merge_request.user = current_user
    @target_branches = @merge_request.target_branches_for_selection
    render :partial => "target_branches", :layout => false
  end

  def show
    merge_request = authorize_access_to(@repository.merge_requests.public.find_by_sequence_number!(params[:id], :include => [:source_repository, :target_repository]))
    version = merge_request.current_version_number

    begin
      commits = merge_request.commits_to_be_merged
    rescue Grit::Git::GitTimeout
      commits = []
      flash[:error] = "A Git timeout occured. Only metadata is being displayed"
    end

    respond_to do |wants|
      wants.html do
        render(:show, :locals => {
            :merge_request => merge_request,
            :version => version,
            :repository => RepositoryPresenter.new(@repository),
            :comments => merge_request.cascaded_comments,
            :commits => commits,
            :source_repo => RepositoryPresenter.new(merge_request.source_repository),
            :target_repo => RepositoryPresenter.new(merge_request.target_repository),
            :user => merge_request.user
          })
      end
      wants.xml { render(:xml => merge_request.to_xml) }
      wants.patch do
        render(:text => commits.collect(&:to_patch).join("\n"), :content_type => "text/plain")
      end
    end
  end

  def new
    @merge_request = @repository.proposed_merge_requests.new
    @merge_request.user = current_user
    @repositories = filter(@owner.repositories.where("id != ? AND kind != ? AND merge_requests_enabled = ?",
                                                     @repository.id,
                                                     Repository::KIND_TRACKING_REPO,
                                                     true))
    if first = @repository.parent || @repositories.first
      @merge_request.target_repository_id = first.id
    end

    get_branches_and_commits_for_selection
  end

  # This is a static URL the user returns to after accepting the terms
  # for a merge request
  def oauth_return
    redirect_back_or_default "/"
  end

  def terms_accepted
    @merge_request = authorize_access_to(@repository.merge_requests.find_by_sequence_number!(params[:id]))
    if @merge_request.terms_accepted
      @merge_request.add_creation_event(@owner, current_user)
      if @merge_request.has_contribution_notice?
        flash[:notice] = @merge_request.contribution_notice
      end
      flash[:success] = I18n.t("merge_requests_controller.create_success",
        :name => @merge_request.target_repository.name)
    else
      flash[:error] = I18n.t("merge_requests_controller.need_contribution_agreement")
    end
    redirect_to project_repository_merge_request_path(@repository.project,
      @repository, @merge_request)
  end

  def create
    @merge_request = authorize_access_to(@repository.proposed_merge_requests.new(params[:merge_request]))
    @merge_request.user = current_user
    if @merge_request.save_with_next_sequence_number
      merge_request_created
    else
      respond_to do |format|
        format.html {
          @repositories = @owner.repositories.where("id != ?", @repository.id)
          get_branches_and_commits_for_selection
          render :action => "new"
        }
        format.xml { render :xml => @merge_request.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @repositories = filter(@owner.repositories.where("id != ?", @repository.id))
    get_branches_and_commits_for_selection
  end

  def update
    @merge_request.attributes = params[:merge_request]
    ending_commit_changed = @merge_request.ending_commit_changed?
    if @merge_request.save
      @merge_request.publish_notification if ending_commit_changed
      flash[:success] = I18n.t "merge_requests_controller.update_success"
      redirect_to [@repository.project, @repository, @merge_request]
    else
      @repositories = filter(@owner.repositories.where("id != ?", @repository.id))
      get_branches_and_commits_for_selection
      render :action => "edit"
    end
  end

  def destroy
    @merge_request.destroy
    flash[:success] = I18n.t "merge_requests_controller.destroy_success"
    redirect_to [@repository.project, @repository]
  end

  def direct_access
    # One of the very rare occasions we find by id
    merge_request = authorize_access_to(MergeRequest.find(params[:id]))
    project = merge_request.target_repository.project
    repository = merge_request.target_repository
    redirect_to [project, repository, merge_request]
  end

  protected

  def find_repository
    @repository = authorize_access_to(
      @owner.repositories.find_by_name_in_project!(params[:repository_id],
                                                   @containing_project))
    @project = authorize_access_to(@repository.project)
  end

  def merge_request_created
    if @merge_request.acceptance_of_terms_required?
      request_token = obtain_oauth_request_token
      @merge_request.oauth_request_token = request_token
      @merge_request.save
      returning_page = terms_accepted_project_repository_merge_request_path(@repository.project,
                                                                            @merge_request.target_repository,
                                                                            @merge_request)
      store_location(returning_page)
      @redirection_path = request_token.authorize_url
    else
      flash[:success] = I18n.t("merge_requests_controller.create_success",
                               :name => @merge_request.target_repository.name)
      @owner.create_event(Action::REQUEST_MERGE, @merge_request, current_user)
      @merge_request.confirmed_by_user
      @redirection_path = project_repository_merge_request_path(@repository.project,
                                                                @merge_request.target_repository,
                                                                @merge_request)
    end

    respond_to do |format|
      format.html {
        redirect_to @redirection_path
        return
      }
      format.xml { render :xml => @merge_request, :status => :created }
    end
  end

  def find_merge_request
    @merge_request = authorize_access_to(@repository.merge_requests.public.find_by_sequence_number!(params[:id]))
  end

  def obtain_oauth_request_token
    request_token = @merge_request.oauth_consumer.get_request_token("user_login" => current_user.login,
                                                                    "merge_request_id" => @merge_request.id)
    return request_token
  end

   def assert_merge_request_resolvable
    unless can_resolve_merge_request?(current_user, @merge_request)
      respond_to do |format|
        flash[:error] = I18n.t "merge_requests_controller.assert_resolvable_error"
        format.html { redirect_to([@repository.project, @repository, @merge_request]) }
        format.xml  {
          render :text => I18n.t("merge_requests_controller.assert_resolvable_error"),
          :status => :forbidden
        }
      end
      return
    end
  end

  def assert_merge_request_ownership
    if @merge_request.user != current_user
      respond_to do |format|
        flash[:error] = I18n.t "merge_requests_controller.assert_ownership_error"
        format.html { redirect_to([@repository.project, @repository]) }
        format.xml  do
          render :text => I18n.t("merge_requests_controller.assert_ownership_error"),
          :status => :forbidden
        end
      end
      return
    end
  end

  def get_branches_and_commits_for_selection
    @source_branches = @repository.git.branches
    @target_branches = @merge_request.target_branches_for_selection
    @commits = @merge_request.commits_for_selection
  end

  def paginated_mrs(page, per_page)
    paginate(page_free_redirect_options) do
      filter_paginated(page, per_page) do |page|
        @repository.merge_requests.from_filter(params[:status])
          .paginate(:page => page,
                    :per_page => per_page,
                    :order => 'created_at DESC')
      end
    end
  end

  def edit_comment_path(comment)
    target = comment.target
    merge_request = target.is_a?(MergeRequestVersion) ? target.merge_request : target

    edit_project_repository_merge_request_comment_path(@project, @repository, merge_request, comment)
  end

  helper_method :edit_comment_path
end
