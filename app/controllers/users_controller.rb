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
  before_filter :login_required, :only => [:edit, :update]
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
      format.atom { redirect_to(user_feed_path(user, :format => :atom)) }
      format.html do
        # These two are used by the layout
        @atom_auto_discovery_url = user_feed_path(@user, :format => :atom)
        @atom_auto_discovery_title = "Public activity feed"

        render_template("show", {
            :user => @user,
            :events => events,
            :projects => filter(@user.projects.includes(:tags, { :repositories => :project })),
            :repositories => filter(@user.commit_repositories),
            :favorites => filter(@user.favorites.all(:include => :watchable))
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

  def edit
    render_template("edit", :user => current_user)
  end

  def update
    outcome = UpdateUser.new(current_user).execute(params[:user])
    pre_condition_failed(outcome)
    outcome.failure { |user| render_template("edit", :user => user) }

    outcome.success do
      flash[:success] = "Your account details were updated"
      redirect_to user_path
    end
  end

  def destroy
    user = find_user
    return current_user_only_redirect if user != current_user

    if(user.deletable?)
      flash[:success] = I18n.t "users_controller.account_deleted"
      user.destroy
      redirect_to(root_path)
    else
      flash[:error] = I18n.t "users_controller.delete_your_repos_and_projects_first"
      redirect_to(user_path(user))
    end
  end

  protected
  def render_form(user)
    locals = { :user => User.new }
    options = { :layout => "second_generation/application" }
    render_template("new", locals, options)
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
    paginate(page_free_redirect_options) do
      filter_paginated(params[:page], FeedItem.per_page) do |page|
        res = user.events.excluding_commits.paginate({
            :page => page,
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
