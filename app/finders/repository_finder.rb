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
require "gitorious/authorization"

class RepositoryFinder
  include Gitorious::Authorization

  def by_id(id, options = {})
    pid = options.key?(:project_id) ? options[:project_id].to_i : nil
    return Repository.find_by_id_and_project_id(id, pid) if pid
    Repository.find_by_id(id)
  end
end
