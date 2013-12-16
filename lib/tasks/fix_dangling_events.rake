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

desc 'Removes events with missing targets'
task :fix_dangling_events => :environment do
  [Project, User, Group, MergeRequest, Repository].each do |target|
    table_name = target.table_name.to_sym

    events = Event.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = events.target_id").
      where(:target_type => target.name, table_name => { :id => nil })

    puts "[fix_dangling_events] removing #{events.count} events with missing target #{target.name}"

    events.find_in_batches(:batch_size => 100) do |event_batch|
      event_batch.each do |event|
        begin
          event.destroy
        rescue => e
          event.delete
        end
      end
    end
  end
end
