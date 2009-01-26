#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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

class Group < ActiveRecord::Base
  belongs_to :project
  belongs_to :creator, :class_name => "User", :foreign_key => "user_id"
  has_many :memberships
  has_many :members, :through => :memberships, :source => :user
  has_many :repositories, :as => :owner
  
  attr_protected :public
  
  # is this +user+ a member of this group?
  def member?(user)
    members.include?(user)
  end
  
  # returns the Role of +user+ in this group
  def role_of_user(candidate)
    membership = memberships.find_by_user_id(candidate.id)
    return unless membership
    membership.role
  end
  
  def admin?(candidate)
    role_of_user(candidate) == Role.admin
  end
  
  def committer?(candidate)
    [Role.admin, Role.committer].include?(role_of_user(candidate))
  end
end
