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

class RepositoryConfigurationPresenter < Struct.new(:repository)

  def as_json(*)
    repo_path = repository.full_repository_path

    json = {
      id: repository.id,
      repository_id: repository.id,
      full_path: repository.full_repository_path,
    }

    json = add_clone_url(json, repository, :ssh)
    json = add_clone_url(json, repository, :http)
    json = add_clone_url(json, repository, :git)

    json = add_custom_hook_path(json, repo_path, "pre-receive")
    json = add_custom_hook_path(json, repo_path, "post-receive")
    json = add_custom_hook_path(json, repo_path, "update")

    json
  end

  private

  def add_clone_url(json, repository, proto)
    if repository.public_send("#{proto}_cloning?")
      json.merge(:"#{proto}_clone_url" => repository.public_send("#{proto}_clone_url"))
    else
      json
    end
  end

  def add_custom_hook_path(json, repo_path, hook_name)
    custom_hook_path = RepositoryHooks.custom_hook_path(repo_path, hook_name)

    if custom_hook_path
      json.merge(:"custom_#{hook_name.gsub('-', '_')}_path" => custom_hook_path)
    else
      json
    end
  end

end
