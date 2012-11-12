# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

module MessagingTestHelper
  def assert_published(queue, message)
    messages = Gitorious::Messaging::TestAdapter.messages_on(queue)

    messages.each do |msg|
      if message.keys.inject(true) { |r,k| r &= msg[k] == message[k] }
        return true
      end
    end

    raise "#{message.inspect} was not published on queue #{queue} #{messages.inspect}"
  end

  def assert_messages_published(queue, num)
    assert_equal num, Gitorious::Messaging::TestAdapter.messages_on(queue).length, Gitorious::Messaging::TestAdapter.messages_on(queue).inspect
  end

  def clear_message_queue
    Gitorious::Messaging::TestAdapter.clear
  end
end

if defined?(ActiveSupport)
  class ActiveSupport::TestCase
    include MessagingTestHelper

    def self.should_consume(queue_name)
      should "Consume messages from #{queue_name}" do
        klass = self.class.name.sub(/Test$/, "").constantize
        consumer = Gitorious::Messaging::TestAdapter.consumers_for(queue_name).find { |c| c == klass }

        assert_not_nil consumer, "#{klass.name} does not consume messages from #{queue_name}"
      end
    end

    def self.should_map_resque_queues_to_processors(messaging_hub, &block)
      context "#{messaging_hub.name}" do
        yield.each do |jms_queue, processor|
          should "enqueue #{jms_queue} message with #{processor.name}" do
            Resque.expects(:push).with do |queue, envelope|
              queue == jms_queue && envelope[:class] == processor.name &&
                envelope[:args].length == 1 && JSON.parse(envelope[:args].first) == {
                "target_class" => "DummyHub",
                "target_id" => 42
              }
            end

            processor.stubs(:queue).returns(jms_queue)
            hub = messaging_hub.new
            hub.publish(jms_queue, { :target_class => "DummyHub", :target_id => 42 })
          end
        end
      end
    end
  end
end
