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

class CreateTrackingRepositoryCommand < CreateRepositoryCommand
  def initialize(app, repository)
    super(app, repository.project, repository.user, {
        :owner => repository.owner,
        :kind => :tracking
      })
    @repository = repository
  end

  def build(params = nil)
    repository = super(NewRepositoryInput.new({
          :name => "tracking_repository_for_#{@repository.id}",
          :merge_requests_enabled => false
        }))
    repository.parent = @repository
    repository
  end

  def execute(repository)
    save(repository)
    initialize_committership(repository)
    initialize_membership(repository)
    schedule_creation(repository, :queue => "GitoriousTrackingRepositoryCreation")
    repository
  end
end
