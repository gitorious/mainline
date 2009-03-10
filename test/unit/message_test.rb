# encoding: utf-8
#--
#   Copyright (C) 2008-2009 Marius Mathiesen <marius.mathiesen@gmail.com>
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
        registered_state_names = Message.aasm_states.collect(&:name)
        [:unread, :read].each do |state|
          assert registered_state_names.include?(state)
        end
      end
    
      should 'have all the required events' do
        registered_event_names = Message.aasm_events.keys
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
  end
  
  context 'Mass email delivery' do
    should_eventually 'create n messages when supplying several recipients'
  end 

end
