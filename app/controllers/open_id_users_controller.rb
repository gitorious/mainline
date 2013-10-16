# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
require "use_cases/create_openid_user"

class OpenIdUsersController < ApplicationController
  renders_in_global_context
  before_filter :require_identity_url_in_session
  before_filter :require_openid_enabled

  def new
    user = User.new(
      :identity_url => session[:openid_url],
      :email => session[:openid_email],
      :fullname => session[:openid_fullname],
      :login => session[:openid_nickname]
    )
    render_new(user)
  end

  def create
    outcome = CreateOpenIdUser.new.execute(params[:user].merge(:identity_url => session[:openid_url]))
    pre_condition_failed(outcome)
    outcome.failure { |user| render_new(user) }

    outcome.success do |user|
      [:openid_url, :openid_email, :openid_nickname, :openid_fullname].each do |k|
        session.delete(k)
      end
      self.current_user = user
      flash[:success] = "Your user profile was successfully created"
      redirect_to(root_path)
    end
  end

  protected

  def require_identity_url_in_session
    if session[:openid_url].blank?
      flash[:error] = 'OpenID URL must be provided'
      redirect_to login_path(:method => 'openid')
    end
  end

  def require_openid_enabled
    render_unauthorized unless Gitorious::OpenID.enabled?
  end

  def render_new(user)
    render(:new, :locals => { :user => user })
  end
end
