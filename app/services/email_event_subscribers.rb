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

module EmailEventSubscribers
  extend Gitorious::Messaging::Publisher
  QUEUE = "/queue/GitoriousEmailEventSubscribers"

  def self.call(event)
    publish(QUEUE, event_id: event.id)
  end

  class Processor
    include Gitorious::Messaging::Consumer
    consumes QUEUE

    def on_message(message)
      EventMailer.call(Event.find(message['event_id']))
    end
  end

  class EventMailer
    def self.call(event)
      new(event, users_to_notify(event)).notify
    end

    def self.users_to_notify(event)
      conditions = ["notify_by_email = ? and user_id != ?", true, event.user_id]
      favorites = event.project.favorites.where(conditions)
      # Find anyone who's just favorited the target, if it's watchable
      if event.target.respond_to?(:watchers)
        favorites += event.target.favorites.where(conditions)
      end

      favorites.map(&:user).uniq
    end

    def initialize(event, users)
      @event = event
      @users = users
    end

    def notify
      return if event.notifications_disabled?
      users.each do |user|
        notify_about_event(user)
      end
    end

    private

    attr_reader :event, :users

    def notify_about_event(user)
      notification_content = EventRendering::Text.render(event)
      ::Mailer.deliver_favorite_notification(user, notification_content)
    end
  end
end
