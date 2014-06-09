# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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

class EmailEventSubscribersProcessor
  include Gitorious::Messaging::Consumer
  consumes EmailEventSubscribers::QUEUE

  def on_message(message)
    id = message['event_id']
    begin
      event = Event.find(id)
    rescue ActiveRecord::RecordNotFound
      logger.warn("Can't notify subscribers about event with id=#{id}, record doesn't exist")
      return
    end

    EmailEventSubscribers::EventMailer.call(event)
  end
end
