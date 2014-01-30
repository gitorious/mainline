# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

class AddCommitterCommand
  def initialize(user, repository)
    @user = user
    @repository = repository
  end

  def execute(committership)
    committership.save
    committership
  end

  def build(params)
    if params.super_group?
      @repository.committerships.add_super_group!
    else
      committership = @repository.committerships.new_committership
      committership.committer = committer(params)
      committership.creator = @user
      committership.build_permissions(params.permissions)
      committership
    end
  end

  private

  def committer(params)
    if params.login
      return User.find_by_login(params.login)
    end
    Team.find_by_name!(params.group_name)
  end
end

class AddCommitterParams
  include Virtus.model
  attribute :permissions, Array[String]
  attribute :user, Hash
  attribute :group, Hash

  def login
    user["login"]
  end

  def group_name
    group["name"]
  end

  def super_group?
    group_name == "Super Group"
  end
end
