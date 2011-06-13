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

# Stomp backed implementation of the Gitorious messaging API. For use with
# lib/gitorious/messaging
#
# To configure the Stomp connection, set the following keys in your
# gitorious.yml:
#     stomp_server_address (defaults to localhost)
#     stomp_server_port    (defaults to 61613)
#
require "stomp"

begin
  require "activemessaging"
rescue LoadError => err
  # Ok if we just want the publisher
end

module Gitorious::Messaging::StompAdapter
  module Publisher
    # Locate the correct class to pick queue from
    #
    def queue(queue)
      @queues ||= {}
      return @queues[queue] if @queues[queue]

      @connection ||= StompConnection.new
      @queues[queue] = StompQueue.new(queue, @connection)
    end

    def do_publish(queue, message)
      queue(queue).publish(message)
    end
  end

  module Consumer
    def self.included(klass)
      klass.send(:extend, self) if klass != Gitorious::Messaging::Consumer
    end

    def consumes(queue, options = {})
      consumer = Class.new(ApplicationProcessor)
      consumer.processor = self
      def consumer.name; "ActiveMessaging#{processor.name.split('::').last}"; end
      def consumer.to_s; processor.name; end

      sym_name = Gitorious::Messaging::StompAdapter.queue_from_symbolic_name(queue)
      raise "Unable to locate symbolic name for queue #{queue}. Check config/messaging.rb" if sym_name.blank?
      consumer.subscribes_to(sym_name, options)
    end
  end

  def self.queue_from_symbolic_name(queue)
    mapping = ActiveMessaging::Gateway.named_destinations.each do |sym, q|
      return sym if q.value == queue
    end

    nil
  end

  if defined?(ActiveMessaging)
    class ApplicationProcessor < ActiveMessaging::Processor
      attr_reader :processor

      def initialize
        @processor = self.class.processor.new
      end

      def self.processor=(processor)
        @processor = processor
      end

      def self.processor
        @processor
      end

      def on_message(message)
        processor.consume(message)
      rescue Exception => err
        on_error(err)
      end

      def on_error(err)
        notify_on_error(err)
        logger.error "#{processor.class.name}::on_error: #{err.class.name} raised: " + err.message

        if (err.kind_of?(StandardError))
          raise ActiveMessaging::AbortMessageException
        else
          raise err
        end
      end

      protected
      def notify_on_error(err)
        Mailer.deliver_message_processor_error(processor, err)
      end
    end
  end

  class StompConnection
    def connect
      host = GitoriousConfig["stomp_server_address"] || "localhost"
      port = GitoriousConfig["stomp_server_port"] || 61613
      Stomp::Connection.open(nil, nil, host, port, true)
    end

    def connection
      @connection ||= connect
    end
  end

  class StompQueue
    def initialize(queue, connection)
      @queue = queue
      @connection = connection
    end

    def publish(payload)
      connection = @connection.connection

      if connection.respond_to?(:publish)
        connection.publish(@queue, payload, "persistent" => true)
      else
        connection.send(@queue, payload, "persistent" => true)
      end
    end
  end

  if defined?(ActiveMessaging)
    def ActiveMessaging.logger
      Gitorious::Messaging.logger
    end
  end
end
