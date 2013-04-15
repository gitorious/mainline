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
require "virtus"
require "commands/create_repository_command"

class CreateWikiRepositoryCommand < CreateRepositoryCommand
  def initialize(app)
    super(app)
  end

  def build(project)
    project.repositories.new({
        :name => "#{project.slug}#{WikiRepository::NAME_SUFFIX}",
        :merge_requests_enabled => false,
        :user => project.user,
        :owner => project.owner,
        :kind => :wiki
      })
  end

  def execute(repository)
    save(repository)
    initialize_committership(repository)
    schedule_creation(repository, :queue => "GitoriousWikiRepositoryCreation")
    repository
  end
end
