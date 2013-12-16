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

desc 'Removes committerships with missing committer users'
task :fix_dangling_committerships => :environment do
  [User, Group].each do |owner|
    table_name = owner.table_name.to_sym

    committerships = Committership.unscoped.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = committerships.committer_id").
      where(:committer_type => owner.name, table_name => { :id => nil })

    puts "[fix_dangling_committerships] removing #{committerships.count} orphaned committerships"

    committerships.each do |committership|
      begin
        committership.destroy
      rescue => e
        committership.delete
      end
    end
  end
end
