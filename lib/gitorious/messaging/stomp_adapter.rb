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

module Gitorious::Messaging::StompAdapter
  module Publisher
    # Locate the correct class to pick queue from
    #
    def inject(queue)
      @connection ||= StompConnection.new
      StompQueue.new(queue, @connection)
    end
  end

  module Consumer
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
end
