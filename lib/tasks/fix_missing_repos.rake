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

desc "Fixes repositories which are ready, but don't exist on disk"
task :fix_missing_repos => :environment do
  Repository.where(:ready => true).includes(:project).find_each do |r|
    next if File.directory?(RepositoryRoot.expand(r.real_gitdir))

    puts "Fixing repository: #{r.project.to_param}/#{r.to_param}"
    Gitorious::App.publish("/queue/GitoriousProjectRepositoryCreation", :id => r.id)
  end
end
