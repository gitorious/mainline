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

class RepositoryCommunityController < ApplicationController
  renders_in_site_specific_context

  def index
    project = Project.find_by_slug(params[:project_id])
    repository = Repository.find_by_name_in_project!(params[:repository_id], project)

    render(:action => :index, :locals => {
        :repository => RepositoryPresenter.new(repository),
        :atom_auto_discovery_url => project_repository_path(repository.project, repository, :format => :atom),
        :atom_auto_discovery_title => "#{repository.title} ATOM feed"
      })
  end
end
