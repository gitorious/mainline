# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 August Lilleaas <augustlilleaas@gmail.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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
require "uri"
require "openid"
require "gitorious"
require "gitorious/authentication/configuration"
require "gitorious/authentication/kerberos_authentication"
require "gitorious/authentication/credentials"
require 'open_id_authentication'

# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  skip_before_filter :public_and_logged_in
  renders_in_site_specific_context
  before_filter :validate_request_host, :only => :create

  include OpenIdAuthentication::ControllerMethods

  def new
  end

  def create
    if using_open_id?
      open_id_authentication(params[:openid_url])
    else
      password_authentication(params[:email], params[:password])
    end
  end

  # This controller action should be protected behind a web server
  # single sign-on authentication mechanism, like Apache's mod_auth_kerb
  # or mod_ssl.
  def http
    http_authentication
  end

  def destroy
    self.current_user.forget_me if logged_in?
    self.current_user = nil
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  protected
  def validate_request_host
    if !Gitorious.site.can_share_cookies?(request.host)
      Rails.logger.warn("WARNING: Invalid request host '#{request.host}'. Session cookies will not work")
    end
  end

  # if user does not exist, it gets created and activated,
  # else if the user already exists with same identity_url, it just logs in
  def open_id_authentication(openid_url)
    if !Gitorious::OpenID.enabled?
      flash[:error] = "OpenID authentication is disabled"
      redirect_to :action => "new" and return
    end
    authenticate_with_open_id(openid_url, :required => [:nickname, :email], :optional => [:fullname]) do |result, identity_url, registration|
      if result.successful?
        @user = User.find_or_initialize_by_identity_url(identity_url)
        if @user.new_record?

          session[:openid_nickname] = registration['nickname']
          session[:openid_email]    = registration['email']
          session[:openid_fullname] = registration['fullname']
          session[:openid_url]      = identity_url
          flash[:notice] = "You now need to finalize your account"
          redirect_to :controller => "open_id_users", :action => "new" and return
        end
        self.current_user = @user
        successful_login
      else
        failed_login result.message, 'openid'
      end
    end
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = %Q{This login (#{@user.login}) already exists, please choose another one}
    redirect_to login_path(:method => 'openid')
  end

  def password_authentication(email, password)
    credentials = Gitorious::Authentication::Credentials.new
    credentials.username = email
    credentials.password = password
    self.current_user = Gitorious::Authentication.authenticate(credentials)
    if logged_in?
      successful_login
    else
      failed_login("Email and/or password did not match, please try again.")
    end
  end

  # Single sign-on, via a web server's authentication mechanism.
  def http_authentication
    credentials = Gitorious::Authentication::Credentials.new
    credentials.env = request.env
    self.current_user = Gitorious::Authentication.authenticate(credentials)
    if logged_in?
      successful_login
    else
      # If the web server is protecting this sessions URL, you might end up
      # with an HTTP 401 error, in which case you won't even get this far.
      # Still, it could happen, if you do some further application-level checks
      # within your Gitorious::Authentication module.
      failed_login "Gitorious could not verify your browser's credentials.", 'http'
    end
  end

  def failed_login(message = "Authentication failed.",method="")
    if method==""
      flash.now[:error] = message
      render :action => 'new'
    else
      redirect_to login_path(:method=>method)
      flash[:error] = message
    end
  end

  def successful_login
    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = {
        :value => self.current_user.remember_token ,
        :expires => self.current_user.remember_token_expires_at,
        :domain => ".#{Gitorious.host}",
        :secure => Gitorious.site.ssl?
      }
    end
    check_state_and_redirect(return_to)
  end

  def check_state_and_redirect(redirection_url)
    if current_user.pending?
      flash[:notice] = "You need to accept the terms"
      redirect_to user_license_path(current_user) and return
    else
      flash[:notice] = "Logged in successfully"
      redirect_back_or_default(redirection_url)
    end
  end

  def return_to
    return URI.parse(params["return_to"]).path if params["return_to"]
    "/"
  end
end
