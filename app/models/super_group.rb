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

class SuperGroup
  def self.model_name
    Group.model_name
  end

  def self.human_name
    Group.human_name
  end

  def self.id
    "super"
  end

  def to_param_with_prefix
    "Super Group*"
  end

  def self.super_committership(committerships)
    cs = committerships.new_committership
    cs.created_at = committerships.repository.created_at
    def cs.committer
      SuperGroup.new
    end
    def cs.persisted?
      true
    end
    def cs.id
      SuperGroup.id
    end
    cs
  end
end
