# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < ActiveSupport::TestCase
  should_belong_to :sender
  should_belong_to :recipient
  should_require_attributes :subject, :body
  should_belong_to :notifiable
  should_have_many :replies
  
  context 'The state machine' do
    context 'class level' do
      should 'have all the required states' do
        registered_state_names = Message.state_machines[:aasm_state].states.collect(&:name)
        [:unread, :read].each do |state|
          assert registered_state_names.include?(state)
        end
      end
    
      should 'have all the required events' do
        # Yeah, I know this is a bit brute, will refactor once all the models are migrated
        registered_event_names = Message.state_machines[:aasm_state].events.instance_variable_get("@nodes").collect(&:name)
        [:read].each {|e| assert registered_event_names.include?(e)}
      end
    end
    
    context 'instance level' do
      setup do 
        @message = messages(:johans_message_to_moe)
        @recipient = @message.recipient
        assert_not_nil(@recipient)
      end
      
      should 'transition to read when the user reads it' do
        unread_message_count = @recipient.received_messages.unread_count
        @message.read!
        assert_equal(unread_message_count - 1, @recipient.received_messages.unread_count)
      end
    end
  end
  
  context 'Replying to a message' do
    setup do
      @sender     = users(:johan)
      @recipient  = users(:moe)
      @message    = messages(:johans_message_to_moe)
      @reply = @message.build_reply(:body => "Thanks. That's much appreciated")
    end

    should 'set the sender and recipient correctly' do
      assert_equal @message.recipient, @reply.sender
      assert_equal @message.sender, @reply.recipient
    end
    
    should 'be able to override the subject of a message' do
      @reply = @message.build_reply(:body => "Thanks. That's much appreciated", :subject => "WTF")
      assert_equal("WTF", @reply.subject)
    end

    should 'set a default subject when replying to a message' do
      assert_equal("Re: #{@message.subject}", @reply.subject)
    end

    should 'flag which message the reply relates to' do
      assert_equal @message, @reply.in_reply_to
    end
    
    should "add to its original messages's responses" do
      assert @reply.save
      assert @message.replies.include?(@reply)
    end
  end
  
  context 'Calculating the number of messages in a thread' do
    setup do
      @sender     = users(:johan)
      @recipient  = users(:moe)
      @message    = messages(:johans_message_to_moe)
    end
    
    should 'calculate the number of unread messages' do
      assert_equal(1, @message.number_of_messages_in_thread)
      reply = @message.build_reply(:body => "Thanks so much")
      assert reply.save
      10.times do 
        new_reply = reply.build_reply(:body => "That's nothing")
        new_reply.save
        reply = new_reply
      end
      @message.replies.reload
      assert_equal(12, @message.number_of_messages_in_thread)      
    end
    
    should 'know which messages are in the same thread' do
      reply = @message.build_reply(:body => 'Yeah')
      reply.save
      reply_to_reply = reply.build_reply(:body=>"Nope")
      reply_to_reply.save
      assert @message.messages_in_thread.include?(reply_to_reply)
    end
    
    should 'know whether there are any unread messages in the thread' do
      @message.read!
      assert !@message.unread_messages?
      reply = @message.build_reply(:body => "This isn't read yet")
      reply.save
      @message.replies.reload
      assert @message.unread_messages?
      reply.read!
      @message.replies.reload
      assert !@message.unread_messages?
    end
  end
  
  
  context 'Email notifications' do
    setup do 
      @moe = users(:moe)
      @mike = users(:mike)
      @message = Message.new(:subject => "Hello", :body => "World")
    end
    
    should 'fire a notification event on message creation' do
      assert @mike.wants_email_notifications?
      @message.sender = @moe
      @message.recipient = @mike
      @message.expects(:schedule_email_delivery).once
      @message.save
    end
    
    should 'not fire a notification event for opt-out users' do
      assert !@moe.wants_email_notifications?
      @message.sender = @mike
      @message.recipient = @moe
      @message.expects(:schedule_email_delivery).never
      @message.save
    end
    
    should 'actually send the message to the queue' do
      p = proc{
        @message.sender = @moe
        @message.recipient = @mike
        @message.save
      }
      message = find_message_with_queue_and_regexp('/queue/GitoriousEmailNotifications', /email_delivery/) {p.call}
      assert_equal(@moe.id, message['sender_id'])
      assert_equal(@mike.id, message['recipient_id'])
      assert_equal(@message.subject, message['subject'])
    end
    
    should 'not send a notification when the sender and recipient is the same person' do
      @message.sender = @message.recipient = @mike
      assert @message.recipient.wants_email_notifications?
      @message.expects(:schedule_email_delivery).never
      @message.save
    end
  end
  
  context 'Rendering XML' do
    setup {@message = Message.first}
    should 'include required attributes' do
      result = @message.to_xml
      assert_match /<recipient_name>#{@message.recipient.title}<\/recipient_name>/, result
    end
  end
  
  context 'Mass email delivery' do
    should_eventually 'create n messages when supplying several recipients'
  end
  
  context "Thottling" do
    setup do
      Message.destroy_all
    end
    
    should "not throttle system notifications" do
      assert_nothing_raised do
        15.times{|i|
          @message = Message.new({:subject => "Hello#{i}", :body => "World"})
          @message.sender = users(:moe)
          @message.recipient = users(:mike)
          @message.notifiable = MergeRequest.first
          @message.save!
        }
      end
    end
    
    should "throttle on create" do
      assert_nothing_raised do
        10.times{|i|
          @message = Message.new({:subject => "Hello#{i}", :body => "World"})
          @message.sender = users(:moe)
          @message.recipient = users(:mike)
          @message.save!
        }
      end
      
      assert_no_difference("Message.count") do
        assert_raises(RecordThrottling::LimitReachedError) do
          @message = Message.new({:subject => "spam much?", :body => "World"})
          @message.sender = users(:moe)
          @message.recipient = users(:mike)
          @message.save!
        end
      end
      
      # Should inflict with others
      assert_difference("Message.count") do
        assert_nothing_raised do
          @message = Message.new({:subject => "spam much?", :body => "World"})
          @message.sender = users(:mike)
          @message.recipient = users(:moe)
          @message.save!
        end
      end
    end
  end

end
