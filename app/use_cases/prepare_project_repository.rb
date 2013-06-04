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
require "use_case"
require "commands/create_project_repository_command"

class PrepareProjectRepository
  include UseCase

  def initialize(app, project, user)
    input_class(NewRepositoryInput)
    add_pre_condition(RequiredDependency.new(:user, user))
    add_pre_condition(AdminRequired.new(app, project.owner, user))
    create_project_repo = CreateProjectRepositoryCommand.new(app, project, user)
    name = project.repositories.mainlines.count == 0 ? project.slug : ""
    step(lambda { |repo| repo }, :builder => lambda do |params|
        params["name"] ||= name
        create_project_repo.build(params)
      end)
  end
end
