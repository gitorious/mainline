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
require "repository_json_presenter"

class RepositoryViewStateController < ApplicationController
  include DoltViewHelpers

  def show
    respond_to do |format|
      repo = Repository.find_by_id(params[:id])
      presenter = RepositoryJSONPresenter.new(self, repo)
      format.json { render(:json => presenter.render_for(current_user)) }
    end
  end
end
