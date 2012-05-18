# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
class Team

  def self.group_implementation
    @group_implementation
  end

  def self.group_implementation=(klass)
    @group_implementation = klass
  end

  self.group_implementation = Group
  
  def self.paginate_all(current_page = nil)
    group_implementation.paginate(:all, :page => current_page)
  end

  def self.find_by_name!(name)
    group_implementation.find_by_name!(name,
                        :include => [:members, :projects, :repositories, :committerships])
  end

  def self.new_group
    group_implementation.new
  end

  def self.create_group(params, user)
    group = group_implementation.new(params)
    group.transaction do
      group.creator = user
      group.save!
      group.memberships.create!({
        :user => user,
        :role => Role.admin,
      })
    end
    return group
  end

  def self.update_group(group, description, avatar)
    group.description = description
    group.avatar = avatar
    group.save!
  end

  class DestroyGroupError < StandardError
  end
  
  def self.destroy_group(name, user)
    group = group_implementation.find_by_name! name
    unless user.is_admin? 
      raise DestroyGroupError, "You're not admin" unless group_admin?(group, user)
      raise DestroyGroupError, "Teams with current members or projects cannot be deleted" unless group.deletable?
    end
    group.destroy
  end

  def self.group_admin?(group, user)
    return false unless user.is_a? User
    role = group.user_role(user)
    role && role.admin?
  end

  def self.delete_avatar(group)
    group.avatar.destroy
    group.save
  end

end
