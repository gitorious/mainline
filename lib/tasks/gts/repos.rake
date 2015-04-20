# encoding: utf-8
#--
#   Copyright (C) 2015 Gitorious AS
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

namespace :gts do
  desc 'Unhash repository paths'
  task unhash_repo_paths: :environment do
    require 'fileutils'

    if ENV['REPO_IDS']
      find_opts = { conditions: { id: ENV['REPO_IDS'].split(/[,\s]/).map(&:to_i) } }
    else
      find_opts = {}
    end

    Project.send(:with_exclusive_scope) do # disable default_scope
      Repository.find_each(find_opts) do |repository|
        if repository.hashed_path != repository.url_path
          puts "unhashing #{repository.url_path} (#{repository.id})..."

          repository.transaction do
            old_path = repository.full_repository_path
            new_path = RepositoryRoot.expand(repository.gitdir).to_s
            new_dir = new_path.split('/')[0..-2].join('/')

            puts "old path: #{old_path}"
            puts "new path: #{new_path}"

            raise "target path exists: #{new_path}" if File.exist?(new_path)

            # update db
            repository.hashed_path = repository.url_path
            repository.save!

            if repository.ready?
              # move repo directory
              FileUtils.mkdir_p(new_dir)
              FileUtils.mv(old_path, new_path)

              # fix hooks symlinks (they're relative)
              RepositoryHooks.create(Pathname(new_path))
            else
              puts "warning: repository doesn't exist on disk"
            end
          end
        end
      end
    end
  end
end
