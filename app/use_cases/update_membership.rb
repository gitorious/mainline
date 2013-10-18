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

class UpdateMembershipCommand
  attr_reader :membership

  def initialize(membership)
    @membership = membership
  end

  def execute(membership)
    membership.save!
    membership
  end

  def build(params)
    membership.role_id = params.role_id
    membership
  end
end

class UpdateMembershipParams
  include Virtus.model

  attribute :role_id, String
end

class UpdateMembership
  include UseCase

  def initialize(membership)
    input_class(UpdateMembershipParams)
    step(UpdateMembershipCommand.new(membership), :validator => MembershipValidator)
  end
end
