#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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
  skip_before_filter :public_and_logged_in, :only => [:activate, :forgot_password, :reset_password]
  
  # render new.rhtml
  def new
  end
  
  def show
    @user = User.find_by_login!(params[:id])
    @projects = @user.projects.find(:all, :include => [:tags, { :repositories => :project }])
    @repositories = @user.repositories.find(:all, :conditions => ["mainline = ?", false])
    @events = @user.events.paginate(:all, 
      :page => params[:page],
      :order => "events.created_at desc", 
      :include => [:user, :project])
    
    @commits_last_week = @user.events.count(:all, 
      :conditions => ["created_at > ? AND action = ?", 7.days.ago, Action::COMMIT])
    @atom_auto_discovery_url = formatted_feed_user_path(@user, :atom)
    
    respond_to do |format|
      format.html { }
      format.atom { redirect_to formatted_feed_user_path(@user, :atom) }
    end
  end
  
  def feed
    @user = User.find_by_login!(params[:id])
    @events = @user.events.find(:all, :order => "events.created_at desc", 
      :include => [:user, :project], :limit => 30)
    respond_to do |format|
      format.html { redirect_to user_path(@user) }
      format.atom { }
    end
  end

  def create
    @user = User.new(params[:user])
    @user.login = params[:user][:login]
    @user.save!    
    flash[:notice] = I18n.t "users_controller.create_notice"
    redirect_to root_path
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def activate
    if user = User.find_by_activation_code(params[:activation_code])
      self.current_user = user
      if logged_in? && !current_user.activated?
        current_user.activate
        flash[:notice] = I18n.t "users_controller.activate_notice"
      end
    else
      flash[:error] = I18n.t "users_controller.activate_error"
    end
    redirect_back_or_default('/')
  end
  
  def forgot_password
  end
    
  def reset_password
    if params[:user] && user = User.find_by_email(params[:user][:email])
      # FIXME: should really be a two-step process: receive link, visiting it resets password
      generated_password = user.reset_password!
      Mailer.deliver_forgotten_password(user, generated_password)
      flash[:notice] = I18n.t "users_controller.reset_password_notice"
      redirect_to(root_path)
    else
      flash[:error] = I18n.t "users_controller.reset_password_error"
      redirect_to forgot_password_users_path
    end
  end
end
