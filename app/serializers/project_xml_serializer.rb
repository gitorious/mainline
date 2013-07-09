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
class ProjectXMLSerializer
  def initialize(app, projects)
    @app = app
    @projects = projects
  end

  def render(user)
    prolog = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    @projects.inject("#{prolog}<projects type=\"array\">") do |xml, p|
      mainlines = @app.filter_authorized(user, p.repositories.mainlines)
      clones = @app.filter_authorized(user, p.repositories.clones)
      xml + p.to_xml({ :skip_instruct => true }, mainlines, clones)
    end + "</projects>"
  end
end
