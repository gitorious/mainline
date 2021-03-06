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

desc "Remove favorites pointing to non-existing records"
task :fix_dangling_favorites => :environment do
  watchables = [Repository, MergeRequest, Project]

  watchables.each do |type|
    table_name = type.table_name.to_sym
    favorites = Favorite.joins("left outer join #{table_name} on #{table_name}.id = favorites.watchable_id")
                        .where(:watchable_type => type.name, table_name => { :id => nil})

    puts "Removing #{favorites.count} dangling favorites for #{type.name}"
    favorites.each(&:delete)
  end
end
