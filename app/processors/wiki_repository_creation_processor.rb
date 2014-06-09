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

class WikiRepositoryCreationProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousWikiRepositoryCreation"

  def on_message(message)
    id = message["id"].to_i
    begin
      repository = Repository.find(id)
    rescue ActiveRecord::RecordNotFound
      logger.warn("Can't create wiki repository on disk for id=#{id}, record doesn't exist")
      return
    end

    logger.info("Processing new wiki repository: #<Repository id: #{repository.id}, path: #{repository.repository_plain_path}>")
    full_path = RepositoryRoot.expand(repository.real_gitdir)
    GitBackend.create(full_path.to_s)
    RepositoryHooks.create(full_path)
    repository.ready = true
    repository.save!
  end
end
