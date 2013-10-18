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

MembershipValidator = UseCase::Validator.define do
  validates :group, :user, :role, :login, :presence => true
  validate :unique_user
  validate :group_creator_unchallenged, :if => :persisted?

  def self.model_name
    Membership.model_name
  end

  def unique_user
    errors.add(:login, "is already a member of this team") unless uniq?
  end

  def group_creator_unchallenged
    errors.add(:role_id, "The group creator cannot be demoted") if creator_demoted?
  end

  private

  def creator_demoted?
    group.creator == user && role != Role.admin
  end
end
