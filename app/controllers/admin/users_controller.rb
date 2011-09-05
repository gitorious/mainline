# encoding: utf-8
#--
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
class Admin::UsersController < ApplicationController
  before_filter :login_required
  before_filter :require_site_admin

  def index
    @users = paginate(:action => "index") do
      User.paginate(:all, :order => 'suspended_at, login', :page => params[:page])
    end

    return if @users.length == 0 && params.key?(:page)

    respond_to do |wants|
      wants.html
    end
  end

  def new
    @user = User.new
    respond_to do |wants|
      wants.html
    end
  end

  def create
    @user = User.new(params[:user])
    @user.login = params[:user][:login]
    @user.is_admin = params[:user][:is_admin] == "1"
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]

    respond_to do |wants|
      if @user.save
        @user.activate
        flash[:notice] = I18n.t "admin.users_controller.create_notice"
        wants.html { redirect_to(admin_users_path) }
        wants.xml { render :xml => @user, :status => :created, :location => @user }
      else
        wants.html { render :action => "new" }
        wants.xml { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end


  def suspend
    @user = User.find_by_login!(params[:id])
    @user.suspended_at = Time.now
    if @user.save
      flash[:notice] = I18n.t "admin.users_controller.suspend_notice", :user_name => @user.login
    else
      flash[:error] = I18n.t "admin.users_controller.suspend_error", :user_name => @user.login
    end
    redirect_to admin_users_url()
  end

  def unsuspend
    @user = User.find_by_login!(params[:id])
    @user.suspended_at = nil
    if @user.save
      flash[:notice] = I18n.t "admin.users_controller.unsuspend_notice", :user_name => @user.login
    else
      flash[:error] = I18n.t "admin.users_controller.unsuspend_error", :user_name => @user.login
    end
    redirect_to admin_users_url()
  end

  def reset_password
#    if params[:user] && user = User.find_by_email(params[:user][:email])
    if user = User.find_by_login(params[:id])
      # FIXME: should really be a two-step process: receive link, visiting it resets password
      generated_password = user.reset_password!
      Mailer.deliver_forgotten_password(user, generated_password)
      flash[:notice] = I18n.t "users_controller.reset_password_notice"
    else
      flash[:error] = I18n.t "users_controller.reset_password_error"
    end
    redirect_to admin_users_url()
  end

  private

  def require_site_admin
    unless current_user.site_admin?
      flash[:error] = I18n.t "admin.users_controller.check_admin"
      redirect_to root_path
    end
  end
end
