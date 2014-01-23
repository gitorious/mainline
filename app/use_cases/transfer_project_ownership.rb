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
require "virtus"
require "project_validator"

class TransferProjectOwnershipCommand
  def initialize(project, user)
    @project = project
    @user = user
  end

  def execute(project)
    project.save!

    project.repositories.mainlines.each do |repo|
      repo.committerships.update_owner(project.owner, user)
    end

    project
  end

  def build(params)
    owner = params.get_owner(user)
    project.wiki_repository.owner = owner
    project.owner = owner
    project
  end

  private
  attr_reader :project, :user
end

class TransferProjectOwnershipParams
  include Virtus.model

  attribute :owner_id, Integer
  attribute :owner_type, String

  def get_owner(user)
    return User.find(owner_id) if owner_type == "User"
    groups = Team.by_admin(user)
    groups.detect { |group| group.id == owner_id }
  end
end

class TransferProjectOwnership
  include UseCase

  def initialize(app, project, user)
    input_class(TransferProjectOwnershipParams)
    add_pre_condition(AdminRequired.new(app, project, user))
    step(TransferProjectOwnershipCommand.new(project, user), :validator => ProjectValidator)
  end
end
