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

desc 'Removes projects with missing owners'
task :fix_dangling_projects do
  [User, Group].each do |owner|
    table_name = owner.table_name.to_sym

    projects = Project.unscoped.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = projects.owner_id").
      where(:owner_type => owner.name, table_name => { :id => nil })

    puts "[fix_dangling_projects] removing #{projects.count} orphaned projects"

    projects.each do |project|
      begin
        project.destroy
      rescue => e
        project.delete
      end
    end
  end
end
