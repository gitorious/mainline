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
require "create_project_command"
require "project_proposal_required"

class PrepareProject
  include UseCase

  def initialize(app, user)
    input_class(NewProjectParams)
    add_pre_condition(RequiredDependency.new(:user, user))
    add_pre_condition(ProjectProposalRequired.new(user))
    create_project = CreateProjectCommand.new(user)
    step(lambda { |project| project }, :builder => create_project)
  end
end
