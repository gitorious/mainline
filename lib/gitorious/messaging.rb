# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
require 'json'

# See lib/gitorious/messaging/ for possible implementations
module Gitorious
  module Messaging

    module Publisher
      # Find the queue by name. This method wraps +inject+ and caches the result
      # the first time it is called. The +inject+ method must be provided by an
      # implementation, and should return an object that supports the +publish+
      # method (see +publish+ below).
      #
      def queue(name)
        @queue ||= inject(name)
      end

      # Publishes a message to the named queue, which isresolved through +queue+.
      # The payload is JSON encoded before passed to the queue's +publish+ method,
      # and should therefore contain only data that can be safely represented as
      # JSON.
      #
      def publish(queue, payload)
        queue(queue).publish(JSON.unparse(payload))
      end
    end

    def self.configure(config)
      adapter = config["messaging_adapter"] || "stomp"
      require "gitorious/messaging/#{adapter}_adapter"

      # Publisher
      klass = Gitorious::Messaging.const_get("#{adapter.capitalize}Adapter").const_get("Publisher")
      Gitorious::Messaging::Publisher.send(:include, klass)


      # Consumer
      #klass = Gitorious::Messaging.const_get("#{adapter.capitalize}Adapter").const_get("Consumer")
      #Gitorious::Messaging::Consumer.send(:include, klass)
    end
  end
end
