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
  module Authorization
    class Base
      def admin?(candidate, thing)
        return candidate == thing if thing.is_a?(User)
        return project_admin?(candidate, thing) if thing.is_a?(Project)
        return repository_admin?(candidate, thing) if thing.is_a?(Repository)
        return group_admin?(candidate, thing) if thing.is_a?(Group)
        false
      end
    end
  end
end
