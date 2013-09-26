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

class CloneRepositoryInput < NewRepositoryInput
  include Virtus.model
  attribute :login, String
  attribute :owner_type, String
  attribute :owner_id, Integer
end

class CloneRepositoryCommand < CreateRepositoryCommand
  def initialize(app, repository, user)
    super(app, repository.project, user)
    @repository = repository
  end

  def build(params)
    clone = super(params)
    login = params.login || @user.login
    clone.name ||= login ? "#{login}s-#{@repository.name}" : nil
    clone.parent = @repository

    if params.owner_type == "Group"
      clone.owner = clone.user.groups.find(params.owner_id)
      clone.kind = :team
    else
      clone.owner = clone.user
      clone.kind = :user
    end

    clone
  end

  def execute(repository)
    save(repository)
    initialize_committership(repository)
    initialize_membership(repository)
    initialize_favorite(repository)
    create_clone_repository_event(repository)
    schedule_creation(repository, :queue => "GitoriousRepositoryCloning")
    repository
  end

  private
  def create_clone_repository_event(repo)
    type = Action::CLONE_REPOSITORY
    repo.project.create_event(type, repo, repo.user, repo.parent_id)
  end
end
