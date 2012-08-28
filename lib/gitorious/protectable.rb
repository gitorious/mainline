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

module Gitorious
  module Protectable
    def make_private
      add_member(owner)
      reload
      owner
    end

    def make_public
      content_memberships.delete_all
      reload
    end

    def add_member(member)
      return if content_memberships.count(:all, :conditions => ["member_id = ? and member_type = ?",
                                                                member.id, member.class.to_s]) > 0
      content_memberships.create!(:member => member)
    end

    def public?
      content_memberships.length == 0
    end
 
    def private?
      !public?
    end

    def member?(candidate)
      candidate == owner ||
        (owner.respond_to?(:member?) && owner.member?(candidate)) ||
        content_memberships.any? { |m| is_member?(candidate, m.member) }
    end
  end
end
