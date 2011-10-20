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
  should_validate_presence_of :subject, :body
  should_belong_to :notifiable
  should_have_many :replies
  
  context 'The state machine' do
    setup do
      @recipient = Factory.create(:user)
      @sender = Factory.create(:user)
    end
    
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
        @message = Factory.create(:message, :sender => @sender, :recipient => @recipient)
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
      @message    = Factory.create(:message)
      @reply = @message.build_reply(:body => "Thanks. That is much appreciated")
    end

    should 'set the sender and recipient correctly' do
      assert_equal @message.recipient, @reply.sender
      assert_equal @message.sender, @reply.recipient
    end
    
    should 'be able to override the subject of a message' do
      @reply = @message.build_reply(:body => "Thanks. That is much appreciated", :subject => "WTF")
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
    
    should 'set the root message' do
      assert @reply.save
      assert_equal @message, @reply.root_message
    end
    
    should 'flag the root message as having unread messages when a new reply is created' do
      assert !@message.has_unread_replies?
      assert @reply.save
      assert @message.reload.has_unread_replies?
      @message.update_attribute(:has_unread_replies, false)
      reply_to_reply = @reply.build_reply(:body => 'All right!', :subject => 'Feeling chatty')
      assert reply_to_reply.save
      assert !@message.reload.has_unread_replies?
    end

    should "touch the root message's updated_at" do
      # hardwire the actual object here
      @reply.stubs(:root_message).returns(@message)
      @message.expects(:touch!)
      @reply.save
    end
  end

  context "Last updated on" do
    setup do
      @message = Message.new(:sender => users(:johan), :recipient => users(:moe),
        :subject => "Hey", :body => "thanks")
      @message.save
    end

    should "be set to current time on creation" do
      assert_not_nil @message.last_activity_at
    end
    
    should "set last_activity_on to now on touch!" do
      original_update_time = 1.hour.ago
      @message.last_activity_at = original_update_time
      @message.touch!
      assert @message.last_activity_at > original_update_time
    end
  end
  
  context 'Calculating the number of messages in a thread' do
    setup do
      @message = Factory.create(:message)
    end
    
    should 'calculate the number of unread messages' do
      assert_equal(1, @message.number_of_messages_in_thread)
      reply = @message.build_reply(:body => "Thanks so much")
      assert reply.save
      5.times do 
        new_reply = reply.build_reply(:body => "That is nothing")
        new_reply.save
        reply = new_reply
      end
      @message.replies.reload
      assert_equal(7, @message.number_of_messages_in_thread)      
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
      reply = @message.build_reply(:body => "This is not read yet")
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
      @privacy_lover = Factory.create(:user, :wants_email_notifications => false)
      @email_lover = Factory.create(:user, :wants_email_notifications => true)
      # @moe = users(:moe)
      # @mike = users(:mike)
      @message = Message.new(:subject => "Hello", :body => "World")
      clear_message_queue
    end
    
    should 'fire a notification event on message creation' do
      assert @email_lover.wants_email_notifications?
      @message.sender = @privacy_lover
      @message.recipient = @email_lover
      @message.expects(:schedule_email_delivery).once
      @message.save
    end
    
    should 'not fire a notification event for opt-out users' do
      assert !@privacy_lover.wants_email_notifications?
      @message.sender = @email_lover
      @message.recipient = @privacy_lover
      @message.expects(:schedule_email_delivery).never
      @message.save
    end
    
    should 'actually send the message to the queue' do
      @message.sender = @privacy_lover
      @message.recipient = @email_lover
      @message.save

      assert_published("/queue/GitoriousEmailNotifications", {
                         "sender_id" => @privacy_lover.id,
                         "recipient_id" => @email_lover.id,
                         "subject" => @message.subject
                       })
    end
    
    should 'not send a notification when the sender and recipient is the same person' do
      @message.sender = @message.recipient = @email_lover
      assert @message.recipient.wants_email_notifications?
      @message.expects(:schedule_email_delivery).never
      @message.save
    end
  end

  should "be readable by the sender" do
    message = Message.new(:subject => "Hello", :body => "World")
    message.sender = users(:johan)
    message.recipient = users(:mike)

    assert message.readable_by?(users(:johan))
    assert message.readable_by?(users(:mike))
    assert !message.readable_by?(users(:moe))
  end

  should "be marked as read by the recipient" do
    message = Message.first
    message.sender = users(:johan)
    message.recipient = users(:mike)

    assert_equal "unread", message.aasm_state_for_user(users(:mike))
    message.mark_as_read_by_user(users(:mike))
    assert_equal "read", message.reload.aasm_state_for_user(users(:mike))
  end

  context 'Rendering XML' do
    setup {@message = Factory.create(:message)}
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
      @recipient = Factory.create(:user)
      @sender = Factory.create(:user)
    end
    
    should "not throttle system notifications" do
      assert_nothing_raised do
        15.times{|i|
          @message = Message.new({:subject => "Hello#{i}", :body => "World"})
          @message.sender = @sender
          @message.recipient = @recipient
          @message.notifiable = MergeRequest.first
          @message.save!
        }
      end
    end
    
    should "throttle on create" do
      assert_nothing_raised do
        5.times{|i|
          @message = Message.new({:subject => "Hello#{i}", :body => "World"})
          @message.sender = @sender
          @message.recipient = @recipient
          @message.save!
        }
      end
      
      assert_no_difference("Message.count") do
        assert_raises(RecordThrottling::LimitReachedError) do
          @message = Message.new({:subject => "spam much?", :body => "World"})
          @message.sender = @sender
          @message.recipient = @recipient
          @message.save!
        end
      end
      
      # Should inflict with others
      assert_difference("Message.count") do
        assert_nothing_raised do
          @message = Message.new({:subject => "spam much?", :body => "World"})
          @message.sender = @recipient
          @message.recipient = @sender
          @message.save!
        end
      end
    end
  end
  
  context 'Archive state' do
    setup do
      @sender = Factory.create(:user)
      @recipient = Factory.create(:user)
      @message = Factory.create(:message, :sender => @sender, :recipient => @recipient)
    end
    
    should 'be marked as archived by both sender and recipient when it is the same user' do
      @message = Factory.create(:message, :sender => @sender, :recipient => @sender)
      @message.archived_by(@sender)
      assert @message.archived_by_sender?
      assert @message.archived_by_recipient?
    end
    
    should 'initially be unread_by_both' do
      assert !@message.archived_by_sender?
      assert !@message.archived_by_recipient?
    end
    
    should 'be archived by sender' do
      @message.archived_by(@sender)
      assert @message.archived_by_sender?
      assert !@message.archived_by_recipient?
    end
    
    should 'be archived by recipient' do
      @message.archived_by(@recipient)
      assert @message.archived_by_recipient?
      assert !@message.archived_by_sender?
    end
    
    should 'be archived by both sender and recipient' do
      @message.archived_by(@sender)
      @message.archived_by(@recipient)
      assert @message.archived_by_sender?
      assert @message.archived_by_recipient?
    end
    
    should 'be reset when a reply is created' do
      @message.archived_by(@sender)
      @message.save
      reply = @message.build_reply(:body => "Foo")
      assert reply.save
      assert !@message.reload.archived_by_sender?
      
      @message.archived_by(@recipient)
      @message.save
      reply_to_reply = reply.build_reply(:body => "Kthxbye")
      assert reply_to_reply.save
      assert !@message.reload.archived_by_recipient?
    end
  end

  context "Sender display" do
    setup do
      @sender = Factory.create(:user)
      @recipient = Factory.create(:user)
    end

    should "be sender#title when no notifiable exists" do
      message = Message.create(:sender => @sender, :recipient => @recipient, :subject => "Hey", :body => "Hello earth")
      assert_equal @sender.title, message.sender_name
      assert message.replies_enabled?
    end
    
    should "be Gitorious when a notifiable exists" do
      group = Factory.create(:group, :creator => @sender)
      membership = Membership.build_invitation(@sender,
        :group => group,
        :user => @recipient,
        :role => Role.admin)
      assert membership.save
      assert_not_nil message = membership.messages.first
      assert_equal @sender, message.sender
      assert_equal "Gitorious", message.sender_name
      assert !message.replies_enabled?
    end
  end
  
end
