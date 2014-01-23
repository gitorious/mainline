# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
class GroupFinder
  def count
    Group.count
  end

  def offset(num)
    Group.offset(num)
  end

  def find_by_name!(name)
    includes = [:projects, :repositories, :_committerships, :members]
    Group.find_by_name!(name,:include => includes)
  end

  def new_group(params={})
    Group.new(params)
  end

  def create_group(params, user)
    group = new_group(params)
    begin
      group.transaction do
        group.creator = user
        group.save!
        group.memberships.create!({
                                    :user => user,
                                    :role => Role.admin,
                                  })
      end
    rescue ActiveRecord::RecordInvalid
    end
    return group
  end

  def by_admin(user)
    user.groups.select{|g| Team.group_admin?(g, user) }
  end

  def find(id)
    Group.find(id)
  end

  def by_id(id)
    Group.find_by_id(id)
  end

  def by_name(name)
    Group.find_by_name(name)
  end

  def find_fuzzy(q)
    Group.find_fuzzy(q)
  end

  def for_user(user)
    user.groups
  end
end
