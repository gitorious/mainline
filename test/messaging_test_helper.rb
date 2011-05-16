require File.dirname(__FILE__) + '/test_helper'

class ActiveSupport::TestCase
  def self.should_map_resque_queues_to_processors(messaging_hub, &block)
    context "#{messaging_hub.name}" do
      yield.each do |jms_queue, processor|
        should "enqueue #{jms_queue} message with #{processor.name}" do
          Resque.expects(:enqueue).with do |klass, payload|
            klass == processor && JSON.parse(payload) == {
              "target_class" => "DummyHub",
              "target_id" => 42
            }
          end

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
    assert_equal num, Gitorious::Messaging::TestAdapter.messages_on(queue).length
  end

  def clear_message_queue
    Gitorious::Messaging::TestAdapter.clear
  end
end
