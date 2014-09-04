# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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
require "user_json_presenter"
require "gitorious/view/avatar_helper"

class UserViewStateController < ApplicationController
  include Gitorious::View::AvatarHelper

  def show
    respond_to do |format|
      presenter = UserJSONPresenter.new(self, current_user)
      format.json { render(:json => presenter.render) }
    end
  end
end
