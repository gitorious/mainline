# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class FeedItem < ActiveRecord::Base
  belongs_to :event
  belongs_to :watcher, :class_name => "User"

  def self.bulk_create_from_watcher_list_and_event!(watcher_ids, event)
    return if watcher_ids.blank?
    # Build a FeedItem for all the watchers interested in the event
    sql_values = watcher_ids.map do |an_id|
      "(#{an_id}, #{event.id}, '#{event.created_at.to_s(:db)}', '#{event.created_at.to_s(:db)}')"
    end
    sql = %Q{INSERT INTO feed_items (watcher_id, event_id, created_at, updated_at)
             VALUES #{sql_values.join(',')}}
    ActiveRecord::Base.connection.execute(sql)
  end
end
