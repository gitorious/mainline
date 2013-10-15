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
require "params_finder"

module ParamsModelResolver
  def project; finder.project; end
  def repository; finder.repository; end
  def merge_request; finder.merge_request; end
  def merge_request_version; finder.merge_request_version; end

  def finder
    @finder ||= ParamsFinder.new(self, params, :project => @project, :repository => @repository)
  end
end
