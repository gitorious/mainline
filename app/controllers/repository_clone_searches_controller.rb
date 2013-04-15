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

class RepositoryCloneSearchesController < ApplicationController
  def show
    project = Project.find_by_slug(params[:project_id])
    verify_site_context!(project)
    repository = project.repositories.find_by_name!(params[:id])
    outcome = SearchClones.new(Gitorious::App, repository, current_user).execute(params)

    pre_condition_failed(outcome)

    outcome.success do |repositories|
      render :json => RepositorySerializer.new(self).to_json(repositories)
    end
  end
end
