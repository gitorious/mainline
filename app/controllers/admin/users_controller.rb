# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

module Admin
  class UsersController < AdminController
    include Gitorious::UserAdministration

    def index
      scope = User.order("suspended_at, login")
      page = (params[:page] || 1).to_i

      begin
        users, pages = JustPaginate.paginate(page, User.per_page, scope.count) do |range|
          scope.offset(range.first).limit(range.count)
        end
      rescue RangeError => err
        flash[:error] = "Page #{page} does not exist"
        redirect_to(admin_users_path, :status => 307) and return
      end

      render("index", :locals => { :users => users, :page => page, :total_pages => pages })
    end

    def new
      render :action => "new", :locals => { :user => User.new }
    end

    def create
      outcome = CreateActivatedUser.new.execute(params[:user])
      pre_condition_failed(outcome)

      respond_to do |wants|
        outcome.success do |result|
          flash[:notice] = I18n.t("admin.users_controller.create_notice")
          wants.html { redirect_to(admin_users_path) }
          wants.xml { render :xml => user, :status => :created, :location => user }
        end

        outcome.failure do |user|
          wants.html { render :action => "new", :locals => { :user => user } }
          wants.xml { render :xml => user.errors, :status => :unprocessable_entity }
        end
      end
    end

    def suspend
      @user = User.find_by_login!(params[:id])
      suspend_summary = suspend_user(@user)

      if @user.save
        flash[:notice] = suspend_summary
      else
        flash[:error] = I18n.t("admin.users_controller.suspend_error", :user_name => @user.login)
      end

      redirect_to admin_users_url
    end

    def unsuspend
      @user = User.find_by_login!(params[:id])
      @user.unsuspend
      if @user.save
        flash[:notice] = I18n.t "admin.users_controller.unsuspend_notice", :user_name => @user.login
      else
        flash[:error] = I18n.t "admin.users_controller.unsuspend_error", :user_name => @user.login
      end
      redirect_to admin_users_url()
    end

    def reset_password
      if user = User.find_by_login(params[:id])
        # FIXME: should really be a two-step process: receive link, visiting it resets password
        generated_password = user.reset_password!
        Mailer.forgotten_password(user, generated_password).deliver
        flash[:notice] = I18n.t "users_controller.reset_password_notice"
      else
        flash[:error] = I18n.t "users_controller.reset_password_error"
      end
      redirect_to admin_users_url()
    end

    def flip_admin_status
      @user = User.find_by_login!(params[:id])
      @user.is_admin = !@user.is_admin
      @user.save
      redirect_to admin_users_url()
    end
  end
end
