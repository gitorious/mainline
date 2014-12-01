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

namespace :gts do
  desc 'Upgrade Gitorious database schema and data'
  task upgrade: ['db:migrate', 'db:seed', :fix_data, :regenerate_authorized_keys]

  desc 'Fix data'
  task fix_data: [:fix_dangling_comments, :fix_dangling_memberships, :fix_missing_wiki_repos, :fix_dangling_committerships, :fix_dangling_projects, :fix_system_comments, :fix_dangling_events, :fix_dangling_repositories, :fix_dangling_favorites, :fix_missing_repos]

  desc 'Regenerate authorized_keys'
  task regenerate_authorized_keys: :environment do
    SshKeyFile.regenerate(nil)
  end
end
