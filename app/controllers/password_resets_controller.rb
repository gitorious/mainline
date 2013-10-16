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

class PasswordResetsController < ApplicationController
  skip_before_filter :public_and_logged_in
  renders_in_global_context

  def new
  end

  def generate_token
    user = User.where(:email => params[:user][:email]).first
    outcome = GeneratePasswordResetToken.new(user).execute
    reset_pre_condition_failed(outcome)

    outcome.failure do |validation|
      flash[:error] = validation.errors.messages.values.flatten.join
      redirect_to(forgot_password_users_path)
    end

    outcome.success do |user|
      flash[:success] = "A password confirmation link has been sent to your email address"
      redirect_to(root_path)
    end
  end

  def prepare_reset
    outcome = PreparePasswordReset.new(user_from_token).execute
    reset_pre_condition_failed(outcome)
    outcome.success { |user| render(:reset, :locals => { :user => user }) }
  end

  def reset
    outcome = ResetPassword.new(user_from_token).execute(params[:user])
    reset_pre_condition_failed(outcome)
    outcome.failure { |user| render(:reset, :locals => { :user => user }) }

    outcome.success do |user|
      flash[:success] = "Password updated"
      redirect_to(new_sessions_path)
    end
  end

  private
  def reset_pre_condition_failed(outcome)
    outcome.pre_condition_failed do |f|
      flash[:error] = I18n.t("users_controller.reset_password_error")
      redirect_to(forgot_password_users_path)
    end
  end

  def user_from_token
    User.find_by_password_key(params[:token].to_s)
  end
end
