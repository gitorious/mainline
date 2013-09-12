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

class ProjectJSONPresenter
  def initialize(app, project)
    @app = app
    @project = project
  end

  def render_for(user)
    JSON.dump(hash_for(user))
  end

  def hash_for(user)
    return {} if project.nil?
    is_admin = !!app.admin?(user, project)
    { "project" => {
        "administrator" => is_admin,
      }.merge(is_admin ? project_admin_hash(user): {})
    }
  end

  private
  def project_admin_hash(user)
    hash = { "admin" => {
        "editPath" => app.edit_project_path(project),
        "editSlugPath" => app.edit_slug_project_path(project),
        "destroyPath" => app.confirm_delete_project_path(project),
        "ownershipPath" => app.transfer_ownership_project_path(project),
        "newRepositoryPath" => app.new_project_repository_path(project)
      }
    }
    if Gitorious.private_repositories?
      hash["admin"]["membershipsPath"] = app.project_project_memberships_path(project)
    end
    if app.site_admin?(user) && Gitorious.dot_org?
      hash["admin"]["oauthSettingsPath"] = app.edit_admin_project_oauth_settings_path(project)
    end
    hash
  end

  attr_reader :app, :project
end
