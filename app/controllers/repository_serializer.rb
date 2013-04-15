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
class RepositorySerializer
  def initialize(router)
    @router = router
  end

  def to_json(repositories)
    repositories.map { |repo|
      project_repo_path = @router.project_repository_path(repo.project, repo)
      image = repo.owner.avatar? ?
                repo.owner.avatar.url(:thumb) :
                "/images/default_face.gif"

      { :name => repo.name,
        :description => repo.description,
        :uri => @router.url_for(project_repo_path),
        :img => image,
        :owner => repo.owner.title,
        :owner_type => repo.owner_type.downcase,
        :owner_uri => @router.url_for(repo.owner)
      }
    }.to_json
  end
end
