# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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

module ProjectsHelper
  include RepositoriesHelper
  
  def show_new_project_link?
    if logged_in?
      if GitoriousConfig["only_site_admins_can_create_projects"] && !current_user.site_admin?
        return false
      end
    else
      return false
    end
    true
  end
  
  def wiki_permission_choices
    [
      ["Writable by everyone", Repository::WIKI_WRITABLE_EVERYONE],
      ["Writable by project members", Repository::WIKI_WRITABLE_PROJECT_MEMBERS],
    ]
  end
end
