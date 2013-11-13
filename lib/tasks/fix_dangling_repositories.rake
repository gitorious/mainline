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

desc 'Removes repositories with missing projects'
task :fix_dangling_repositories do
  [User, Project].each do |model|
    table_name = model.table_name.to_sym
    name       = model.name

    repositories = Repository.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = repositories.#{name.underscore}_id").
      where(table_name => { :id => nil })

    puts "[fix_dangling_repositories] removing #{repositories.count} orphaned repositories"

    repositories.each do |repository|
      begin
        repository.destroy
      rescue => e
        repository.delete
      end
    end
  end

  [User, Group].each do |model|
    table_name = model.table_name.to_sym
    name       = model.name

    repositories = Repository.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = repositories.owner_id").
      where(:owner_type => name, table_name => { :id => nil })

    puts "[fix_dangling_repositories] removing #{repositories.count} orphaned repositories"

    repositories.each do |repository|
      begin
        repository.destroy
      rescue => e
        repository.delete
      end
    end
  end
end
