require File.dirname(__FILE__) + '/test_helper'

class ActiveSupport::TestCase
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

  def self.should_consume(queue_name)
    should "Consume messages from #{queue_name}" do
      klass = self.class.name.sub(/Test$/, "").constantize
      consumer = Gitorious::Messaging::TestAdapter.consumers_for(queue_name).find { |c| c == klass }

      assert_not_nil consumer, "#{klass.name} does not consume messages from #{queue_name}"
    end
  end
end
