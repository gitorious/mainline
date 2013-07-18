# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
  include Gitorious::Authorization

  def wiki_permission_choices
    [["Writable by everyone", WikiRepository::WRITABLE_EVERYONE],
     ["Writable by project members", WikiRepository::WRITABLE_PROJECT_MEMBERS]]
  end

  def default_license(project)
    project.license || ProjectLicense.default
  end

  def project_license_choices(options = {})
    selected = options[:selected] || ""
    ProjectLicense.all.inject("") do |html, license|
      description = (license.description || "").gsub(/\n/, " ")
      attr = license.description.nil? ? "" : " data-description=\"#{description}\""
      attr += license.name == selected ? " selected=\"selected\"" : ""
      "#{html}\n<option value=\"#{license.name}\"#{attr}>#{license.name}</option>"
    end
  end

  def license_label(scope = nil)
    Gitorious::Configuration.get("license_label", t("license", :scope => scope))
  end
end
