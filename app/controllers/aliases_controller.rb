# encoding: utf-8
#--
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
class AliasesController < ApplicationController
  before_filter :login_required
  before_filter :find_user
  before_filter :require_current_user
  renders_in_global_context
  
  def index
    @emails = @user.email_aliases
    @root = Breadcrumb::Aliases.new(current_user)
  end
  
  def new
    @email = @user.email_aliases.new
    @root = Breadcrumb::NewAlias.new(current_user)
  end
  
  def create
    @email = @user.email_aliases.new(params[:email])
    
    if @email.save
      flash[:success] = "You will receive an email asking you to confirm ownership of #{@email.address}"
      redirect_to user_aliases_path(@user)
    else
      render "new"
    end
  end
  
  def confirm
    email = current_user.email_aliases.with_aasm_state(:pending).first(:conditions => {:confirmation_code => params[:id]})
    if email
      email.confirm!
      flash[:success] = "#{email.address} is now confirmed as belonging to you"
      redirect_to user_aliases_path(@user) and return
    else
      flash[:error] = "The confirmation is incorrect"
      redirect_to user_path(@user)
    end
  end
  
  def destroy
    @email = @user.email_aliases.find_by_id(params[:id])
    if @email.destroy
      flash[:success] = "Email alias deleted"
    end
    redirect_to user_aliases_path(@user)
  end
  
  protected
    def find_user
      @user = User.find_by_login!(params[:user_id])
    end
end
