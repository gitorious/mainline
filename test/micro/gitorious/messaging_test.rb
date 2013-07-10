# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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
require "fast_test_helper"
require "gitorious/messaging"

module ActiveRecord
  class Base
    def self.verify_active_connections!
    end
  end
end

class DummyPublisher
  include Gitorious::Messaging::Publisher
  attr_accessor :messages

  def do_publish(queue, payload)
    (@messages ||= []) << [queue, payload]
  end
end

class GitoriousMessagingTest < MiniTest::Spec
  describe "publisher" do
    describe "publish" do
      it "calls do_publish with queue and json" do
        publisher = DummyPublisher.new

        publisher.publish("queue_name", :id => 42, :action => "do_it")

        assert_equal 1, publisher.messages.length
        assert_equal "queue_name", publisher.messages.first[0]
        assert_match /"id":42/, publisher.messages.first[1]
        assert_match /"action":"do_it"/, publisher.messages.first[1]
      end
    end
  end

  class DummyConsumer
    include Gitorious::Messaging::Consumer
    def on_message(message); end
  end

  describe "consumer" do
    it "passes JSON parsed message to on_message" do
      consumer = DummyConsumer.new
      consumer.expects(:on_message).with({ "id" => 42 })

      consumer.consume('{"id": 42}')
    end

    it "passes untampered hash message to on_message" do
      consumer = DummyConsumer.new
      consumer.expects(:on_message).with({ :id => 42 })

      consumer.consume({ :id => 42 })
    end

    it "calls on_error if JSON parsing the message fails" do
      consumer = DummyConsumer.new
      consumer.expects(:on_error).with do |err|
        err.class == JSON::ParserError
      end

      consumer.consume("{id}")
    end

    it "calls on_error if on_message raises" do
      consumer = DummyConsumer.new
      consumer.stubs(:on_message).raises(
        Gitorious::Messaging::AbortMessageException.new("Oops"))

      consumer.expects(:on_error).with do |err|
        err.class == Gitorious::Messaging::AbortMessageException &&
          err.message == "Oops"
      end

      consumer.consume({ :id => 42 })
    end

    it "verifies that the ActiveRecord connection is alive" do
      ActiveRecord::Base.expects(:verify_active_connections!)

      consumer = DummyConsumer.new
      consumer.verify_connections!
    end

    it "verifies that the ActiveRecord connection is alive on message" do
      ActiveRecord::Base.expects(:verify_active_connections!)

      consumer = DummyConsumer.new
      consumer.consume('{"id": 42}')
    end
  end
end
