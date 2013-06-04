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

class ListMainlinesCommand
  def initialize(app, project, user)
    @app = app
    @project = project
    @user = user
  end

  def execute(params)
    @app.filter_authorized(@user, @project.repositories.mainlines)
  end
end

class ListMainlines
  include UseCase

  def initialize(app, project, user)
    project = project.is_a?(Integer) ? Project.find_by_id(project) : project
    add_pre_condition(RequiredDependency.new(:project, project))
    step(ListMainlinesCommand.new(app, project, user))
  end
end
