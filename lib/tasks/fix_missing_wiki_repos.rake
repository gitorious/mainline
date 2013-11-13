#--
#   Copyright (C) 2012-2013 Gitorious AS
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

desc "Creates missing wiki repositories"
task :fix_missing_wiki_repos => :environment do
  repo_project_ids = Repository.where(:kind => Repository::KIND_WIKI).pluck(:project_id)
  project_ids = Project.pluck(:id)
  projects_with_missing_wiki = project_ids - repo_project_ids

  puts "Attempting to fix #{projects_with_missing_wiki.count} projects without wiki repo"

  Project.where(:id => projects_with_missing_wiki).each do |project|
    command = CreateWikiRepositoryCommand.new(Gitorious::App)
    repository = command.build(project)
    command.execute(repository)
  end
end
