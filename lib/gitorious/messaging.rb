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
        @queues ||= {}
        @queues[name] ||= inject(name)
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

    module Consumer
      # Subscribe a class as a queue consumer. The class must implement the
      # +#on_message(message)+ and +#on_error(error)+ methods to handle messages
      # on the queue specified by +#consumes(queue)+. Implementations that do
      # not strictly map a single class to handle a single queue needs to work
      # around this assumption in its implementation.
      #
      # Implementing modules should call +#consume(message)+ to consume incoming
      # messages. 
      #
      # def self.consumes(queue, options = {})
      #
      # end

      def self.included(klass)
        if defined? @@macros
          klass.extend(@@macros)
        end
      end

      def self.use(implementation, macros)
        @@adapter = implementation
        @@macros = macros
        include implementation
      end

      def self.configured?
        defined? @@adapter
      end

      # Consumes a message from the queue. The method expects the message to be
      # a hash. It will call +#on_message+ to process the message. If anything
      # goes wrong, either in +#consume+ itself or in +#on_message+, the
      # +#on_error+ method will be called with an error object.
      #
      def consume(json)
        if String === json
          message = JSON.parse(json)
        else
          message = json
          json = JSON.unparse(message)
        end

        logger.debug("#{self.class.name} processing message #{json}")
        verify_connections!
        on_message(message)
      rescue Exception => err
        on_error(err)
      end

      def on_message(message)
        raise NotImplementedError.new("Consumer #{self.class} does not implement the on_message method")
      end

      def on_error(exception)
        raise exception
      end

      def logger
        Gitorious::Messaging.logger
      end

      # verify active database connections, reconnect if needed
      def verify_connections!
        ActiveRecord::Base.verify_active_connections!
      end
    end

    class AbortMessageException < Exception; end

    def self.logger
      return @@logger if defined? @@logger

      filename = "message_processing#{RAILS_ENV == 'test' ? '_test' : ''}"
      io = RAILS_ENV == "development" ? STDOUT : File.join(RAILS_ROOT, "log", "#{filename}.log")
      @@logger = ActiveSupport::BufferedLogger.new(io)
      @@logger.level = ActiveSupport::BufferedLogger::INFO
      @@logger.auto_flushing = true if RAILS_ENV == "production"
      @@logger
    end

    def self.configure(config)
      adapter = config["messaging_adapter"] || "stomp"
      require "gitorious/messaging/#{adapter}_adapter"

      # Publisher
      klass = Gitorious::Messaging.const_get("#{adapter.capitalize}Adapter").const_get("Publisher")
      Gitorious::Messaging::Publisher.send(:include, klass)

      # Consumer
      klass = Gitorious::Messaging.const_get("#{adapter.capitalize}Adapter").const_get("Consumer")
      Gitorious::Messaging::Consumer.use(klass, klass.const_get("Macros"))
    end
  end
end
