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
require File.dirname(__FILE__) + '/../../../../messaging_test_helper'
require "gitorious/messaging"
require "gitorious/messaging/stomp_adapter"

class StompPublisher
  include Gitorious::Messaging::Publisher
  include Gitorious::Messaging::StompAdapter::Publisher
end

class MessagingStompAdapterTest < ActiveSupport::TestCase
  def setup
    @publisher = StompPublisher.new
  end

  def mock_connection
    connection = mock
    connection.stubs(:publish)
    connection
  end

  context "publishing messages" do
    teardown do
      GitoriousConfig.delete("stomp_server_address")
      GitoriousConfig.delete("stomp_server_port")
    end

    should "connect if not connected" do
      conn = mock_connection
      Stomp::Connection.expects(:open).with(nil, nil, "localhost", 61613, true).returns(conn)

      @publisher.publish("/queue/GitoriousRepositoryCreation", {})
    end

    should "not re-connect if connected" do
      conn = mock_connection
      Stomp::Connection.expects(:open).once.returns(conn)

      @publisher.publish("/queue/GitoriousRepositoryCreation", {})
      @publisher.publish("/queue/GitoriousRepositoryCreation", {})
    end

    should "connect to port and host from gitorious.yml" do
      GitoriousConfig["stomp_server_address"] = "lolcathost"
      GitoriousConfig["stomp_server_port"] = 61610
      conn = mock_connection
      Stomp::Connection.expects(:open).with(nil, nil, "lolcathost", 61610, true).returns(conn)

      @publisher.publish("/queue/GitoriousRepositoryCreation", {})
      @publisher.publish("/queue/GitoriousRepositoryCreation", {})
    end

    should "publish to the jms queue" do
      connection = mock
      connection.expects(:publish).with("/queue/GitoriousRepositoryCreation",
                                        '{"id":42}', "persistent" => true)
      Stomp::Connection.expects(:open).returns(connection)

      @publisher.publish("/queue/GitoriousRepositoryCreation", { "id" => 42 })
    end

    should "publish to the jms queue with send for backwards compatibility" do
      connection = mock
      connection.expects(:send).with("/queue/GitoriousRepositoryCreation",
                                     '{"id":42}', "persistent" => true)
      Stomp::Connection.expects(:open).returns(connection)

      @publisher.publish("/queue/GitoriousRepositoryCreation", { "id" => 42 })
    end
  end
end
