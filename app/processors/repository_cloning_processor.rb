# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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

class RepositoryCloningProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousRepositoryCloning"

  def on_message(message)
    id = message["id"].to_i
    begin
      repository = Repository.find(id)
    rescue ActiveRecord::RecordNotFound
      logger.warn("Can't clone repository with id=#{id}, record doesn't exist")
      return
    end

    logger.info("Processing new repository clone: #<Repository id: #{repository.id}, :parent: #{repository.parent.repository_plain_path}, path: #{repository.repository_plain_path}>")
    RepositoryCloner.clone_with_hooks(repository.parent.real_gitdir, repository.real_gitdir)
    repository.ready = true
    repository.disk_usage = repository.parent.disk_usage
    repository.save!
    Gitorious.mirrors.clone_repository(repository.parent, repository)
  end
end
