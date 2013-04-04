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
require "commands/create_repository_command"

class CreateProjectRepositoryCommand < CreateRepositoryCommand
  def initialize(app, project = nil, user = nil)
    super(app, project, user, :kind => :project)
  end

  def execute(repository)
    repository.set_repository_path
    repository.save!
    create_owner_committership(repository)
    repository.make_private if Repository.private_on_create?(:private => private?)
    repository.watched_by!(repository.user)
    repository.project.create_new_repository_event(repository)
    @app.publish("/queue/GitoriousRepositoryCreation", { :id => repository.id })
    repository
  end
end
