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

class PasswordsController < ApplicationController
  renders_in_global_context
  before_filter :login_required

  def update
    input = params[:user].merge(:actor => requested_user)
    outcome = ChangePassword.new(current_user).execute(input)

    outcome.failure do |user|
      flash[:error] = "Password do not match"
      redirect_to user_edit_password_path(current_user)
    end

    pre_condition_failed(outcome) do |f|
      f.when(:current_password_required) do
        flash[:error] = "Your current password does not seem to match the one you supplied"
        redirect_to user_edit_password_path(current_user)
      end
    end

    outcome.success do |user|
      flash[:success] = "Your password has been changed"
      redirect_to user_edit_password_path(current_user)
    end
  end

  private

  def requested_user
    @user ||= User.find_by_login!(params[:id])
  end
end
