#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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

class AccountsController < ApplicationController
  before_filter :login_required
  
  def show
  end
  
  def edit  
    @user = current_user  
  end
  
  def update
    @user = current_user
    @user.attributes = params[:user]
    if current_user.save
      if current_user.pending?
        flash[:notice] = "Please accept the license agreement"
        redirect_to edit_account_path and return
      else
        flash[:notice] = "Your account details were updated"
        redirect_to account_path
      end
    else
      render :action => "edit"
    end
  end
  
  def password
    @user = current_user
  end
  
  def update_password
    @user = current_user
    if User.authenticate(current_user.email, params[:user][:current_password]) || @user.is_openid_only?
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
      if @user.save
        flash[:notice] = "Your password has been changed"
        redirect_to account_path
      else
        render :action => "password"
      end
    else
      flash[:error] = "Your current password doesn't seem to match the one your supplied"
      render :action => "password"
    end
  end
end
