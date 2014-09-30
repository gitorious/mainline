# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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

class UsersController < ApplicationController
  renders_in_global_context
  before_filter :login_required, :only => [:edit, :update, :destroy]
  before_filter :find_user, :only => [:show, :edit, :update]
  before_filter :require_current_user, :only => [:edit, :update]
  before_filter :require_public_user, :only => [:show]
  before_filter :require_registration_enabled, :only => [:new, :create]

  def new
    render_form(User.new)
  end

  def show
    # TODO:
    # ProfileUser.new(User.find_by_login(params[:id])).to_hash
    # Encapsulate data access and require_current_user filter
    # Pre-conditions?

    events = paginated_events(@user)
    return if events.count == 0 && params.key?(:page)

    respond_to do |format|
      format.atom { redirect_to(user_feed_path(@user, :format => :atom)) }
      format.html do
        render(:show, :locals => {
            :user => @user,
            :events => events,
            :teams => Team.for_user(@user),
            :projects => filter(@user.projects.includes(:tags, { :repositories => :project })),
            :repositories => filter(@user.committerships.commit_repositories),
            :favorites => filter(@user.favorites.all(:include => :watchable)),
            :atom_auto_discovery_url => user_feed_path(@user, :format => :atom),
            :atom_auto_discovery_title => "Public activity feed"
          })
      end
    end
  end

  def create
    outcome = CreateUser.new.execute(params[:user])
    pre_condition_failed(outcome)
    outcome.failure { |user| render_form(user) }
    outcome.success { |result| redirect_to(pending_activation_users_url) }
  end

  EDIT_VIEWS = {
    'account'          => 'users/edit/account',
    'email-aliases'    => 'users/edit/email_aliases',
    'ssh-keys'         => 'users/edit/ssh_keys',
    'change-password'  => 'users/edit/change_password',
    'manage-favorites' => 'users/edit/manage_favorites'
  }

  def edit
    active_tab = params.fetch(:tab, 'account')
    locals = { :user => current_user, :active_tab => active_tab }

    if pjax_request?
      partial = EDIT_VIEWS.fetch(active_tab)
      render :partial => partial, :locals => locals
    else
      respond_to do |format|
        format.html do
          render :edit, :locals => locals
        end
      end
    end
  end

  def update
    outcome = UpdateUser.new(current_user).execute(params[:user])
    pre_condition_failed(outcome)

    outcome.failure do |user|
      flash[:error] = "Failed to save your details"
      render(:edit, :locals => { :user => user, :active_tab => 'account' })
    end

    outcome.success do
      flash[:success] = "Your account details were updated"
      redirect_to edit_user_path(current_user)
    end
  end

  def destroy
    user = find_user
    return current_user_only_redirect if user != current_user

    if user.deletable?
      flash[:success] = I18n.t "users_controller.account_deleted"
      user.destroy
      redirect_to(root_path)
    else
      flash[:error] = I18n.t "users_controller.delete_your_repos_and_projects_first"
      redirect_to(user_path(user))
    end
  end

  protected

  def favorites
    @favorites ||= filter(current_user.favorites.all(:include => :watchable))
  end
  helper_method :favorites

  def emails
    @emails ||= current_user.email_aliases
  end
  helper_method :emails

  def render_form(user)
    render(:new, :locals => { :user => user })
  end

  def find_user
    @user = User.find_by_login!(params[:id])
  end

  def require_public_user
    unless @user.public?
      flash[:notice] = "This user profile is not public"
      redirect_back_or_default root_path
    end
  end

  def paginated_events(user)
    collection = user.events.excluding_commits
    paginate(page_free_redirect_options) do
      filter_paginated(params[:page], FeedItem.per_page, collection.count) do |page|
        collection.paginate({
            :page => page,
            :per_page => FeedItem.per_page,
            :order => "events.created_at desc",
            :include => [:user, :project]
          })
      end
    end
  end

  def require_registration_enabled
    render_unauthorized if !Gitorious.registrations_enabled?
  end
end
