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

class UserActivationsController < ApplicationController
  skip_before_filter :public_and_logged_in, :only => [:show, :create]
  before_filter :require_not_logged_in, :only => [:show]

  renders_in_global_context

  def show; end

  def create
    user = logged_in? && current_user
    outcome = ActivateUser.new.execute(:code => params[:activation_code])
    pre_condition_failed(outcome) { return }
    outcome.failure { |user| flash[:error] = I18n.t("users_controller.activate_error") }

    outcome.success do |user|
      self.current_user = user
      flash[:notice] = I18n.t("users_controller.activate_notice")
    end

    redirect_back_or_default("/")
  end
end
