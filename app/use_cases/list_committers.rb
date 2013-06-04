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

class ListCommittersCommand
  def initialize(app, repository, user)
    @app = app
    @repository = repository
    @user = user
  end

  def execute(params)
    @app.filter_authorized(@user, @app.committers(@repository))
  end
end

class ListCommitters
  include UseCase

  def initialize(app, repository, user)
    repository = repository.is_a?(Integer) ? Repository.find_by_id(repository) : repository
    add_pre_condition(RequiredDependency.new(:repository, repository))
    step(ListCommittersCommand.new(app, repository, user))
  end
end
