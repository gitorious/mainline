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
class LdapGroupFinder
  def count
    LdapGroup.count
  end

  def offset(num)
    LdapGroup.offset(num)
  end

  def find_by_name!(name)
    includes = [:projects, :repositories]
    LdapGroup.find_by_name!(name,:include => includes)
  end

  def new_group(params={})
    LdapGroup.new(params)
  end

  def create_group(params, user)
    group = new_group(params)
    begin
      group.transaction do
        group.creator = user
        group.save!
      end
    rescue ActiveRecord::RecordInvalid
    end
    return group
  end

  def by_admin(user)
    LdapGroup.find_all_by_user_id(user.id)
  end

  def find(id)
    LdapGroup.find(id)
  end

  def find_fuzzy(q)
    LdapGroup.find_fuzzy(q)
  end

  def for_user(user)
    LdapGroup.groups_for_user(user)
  end
end
