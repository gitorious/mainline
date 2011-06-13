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
require File.dirname(__FILE__) + '/../../../test_helper'
require "gitorious/messaging"

class DummyPublisher
  include Gitorious::Messaging::Publisher
  attr_accessor :messages

  def do_publish(queue, payload)
    (@messages ||= []) << [queue, payload]
  end

  # class Queue
  #   attr_reader :messages, :name
  #   def initialize(name); @name = name; end
  #   def publish(payload); (@messages ||= []) << JSON.parse(payload); end
  #   def to_s; name; end
  # end

  # def inject(queue)
  #   @counter ||= 1
  #   res = Queue.new("injected: #{queue} ##{@counter}")
  #   @counter += 1
  #   res
  # end
end

class GitoriousMessagingTest < ActiveSupport::TestCase
  context "publisher" do
    # context "queue" do
    #   should "locate queue from inject" do
    #     publisher = DummyPublisher.new

    #     assert_equal "injected: my_queue #1", publisher.queue("my_queue").to_s
    #   end

    #   should "reuse previously injected queue" do
    #     publisher = DummyPublisher.new
    #     queue = publisher.queue("my_queue")

    #     assert_equal "injected: my_queue #1", publisher.queue("my_queue").to_s
    #   end

    #   should "not reuse previously injected queue when name is different" do
    #     publisher = DummyPublisher.new
    #     queue = publisher.queue("my_queue")

    #     assert_equal "injected: my_other #2", publisher.queue("my_other").to_s
    #   end
    # end

    context "publish" do
      should "call do_publish with queue and json" do
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

  context "consumer" do
    should "pass JSON parsed message to on_message" do
      consumer = DummyConsumer.new
      consumer.expects(:on_message).with({ "id" => 42 })

      consumer.consume('{"id": 42}')
    end

    should "pass untampered hash message to on_message" do
      consumer = DummyConsumer.new
      consumer.expects(:on_message).with({ :id => 42 })

      consumer.consume({ :id => 42 })
    end

    should "call on_error if JSON parsing the message fails" do
      consumer = DummyConsumer.new
      consumer.expects(:on_error).with do |err|
        err.class == JSON::ParserError
      end

      consumer.consume("{id}")
    end

    should "call on_error if on_message raises" do
      consumer = DummyConsumer.new
      consumer.stubs(:on_message).raises(
        Gitorious::Messaging::AbortMessageException.new("Oops"))

      consumer.expects(:on_error).with do |err|
        err.class == Gitorious::Messaging::AbortMessageException &&
          err.message == "Oops"
      end

      consumer.consume({ :id => 42 })
    end

    should "verify that the ActiveRecord connection is alive" do
      ActiveRecord::Base.expects(:verify_active_connections!)

      consumer = DummyConsumer.new
      consumer.verify_connections!
    end

    should "verify that the ActiveRecord connection is alive on message" do
      ActiveRecord::Base.expects(:verify_active_connections!)

      consumer = DummyConsumer.new
      consumer.consume('{"id": 42}')
    end
  end
end
