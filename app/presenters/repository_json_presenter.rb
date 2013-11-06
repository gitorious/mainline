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

class RepositoryJSONPresenter
  def initialize(app, repository)
    @app = app
    @repository = repository
  end

  def render_for(user)
    JSON.dump(hash_for(user))
  end

  def hash_for(user)
    return {} if repository.nil?
    is_admin = !!app.admin?(user, repository)
    { "repository" => {
        "name" => repository.name,
        "description" => app.description(repository),
        "administrator" => is_admin,
        "watch" => user && watch(user),
        "cloneProtocols" => clone_protocols(user),
        "clonePath" => clone_path(user),
        "requestMergePath" => request_merge_path(user),
        "openMergeRequestCount" => repository.open_merge_requests.count
      }.merge(is_admin ? repo_admin_hash: {})
    }
  end

  private
  def clone_protocols(user)
    { "protocols" => [] }.tap do |cp|
      cp["protocols"] << "git" if repository.git_cloning?
      cp["protocols"] << "http" if repository.http_cloning?

      if repository.display_ssh_url?(user)
        cp["protocols"] << "ssh"
        cp["default"] = "ssh"
      else
        cp["default"] = repository.default_clone_protocol
      end
    end
  end

  def repo_admin_hash
    { "admin" => {
        "editPath" => app.edit_project_repository_path(project, repository),
        "destroyPath" => app.confirm_delete_project_repository_path(project, repository),
        "ownershipPath" => app.transfer_ownership_project_repository_path(project, repository),
        "committershipsPath" => app.project_repository_committerships_path(project, repository),
        "servicesPath" => app.project_repository_services_path(project, repository)
      }
    }
  end

  def watch(user)
    favorite = user.favorites.find { |f| f.watchable == repository }
    hash = {
      "watching" => !favorite.nil?,
      "watchPath" => app.favorites_path(:watchable_id => repository.id,
        :watchable_type => "Repository")
    }
    hash["unwatchPath"] = app.favorite_path(favorite) if !favorite.nil?
    hash
  end

  def clone_path(user)
    return nil if repository.parent && repository.owner == user
    app.clone_project_repository_path(repository.project, repository)
  end

  def request_merge_path(user)
    return nil if user.nil? || repository.parent.nil? || !app.admin?(user, repository)
    app.new_project_repository_merge_request_path(repository.project, repository)
  end

  attr_reader :app, :repository
  def project; @repository.project; end
end
