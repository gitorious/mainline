# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

require "test_helper"

load Rails.root.join("app/models/message.rb")

class MessageTest < ActiveSupport::TestCase
  should belong_to(:sender)
  should validate_presence_of(:subject)
  should validate_presence_of(:body)
  should belong_to(:notifiable)
  should have_many(:replies)

  context "Replying to a message" do
    setup do
      @message = FactoryGirl.create(:message)
      @recipient = @message.recipients.first
      @reply = @message.build_reply(:body => "Thanks. That is much appreciated",
                                    :sender => @recipient)
    end

    should "require a sender as an argument" do
      assert_raises(KeyError) do
        @message.build_reply(body: "re body")
      end
    end

    should "set the sender and recipient correctly" do
      assert_equal @message.recipient, @reply.sender
      assert_equal @message.sender, @reply.recipient
    end

    should "be able to override the subject of a message" do
      @reply = @message.build_reply(:sender => @recipient,
                                    :body => "Thanks. That is much appreciated",
                                    :subject => "WTF")
      assert_equal("WTF", @reply.subject)
    end

    should "set a default subject when replying to a message" do
      assert_equal("Re: #{@message.subject}", @reply.subject)
    end

    should "flag which message the reply relates to" do
      assert_equal @message, @reply.in_reply_to
    end

    should "add to its original messages' responses" do
      assert @reply.save
      assert @message.replies.include?(@reply)
    end

    should "set the root message" do
      assert @reply.save
      assert_equal @message, @reply.root_message
    end

    should "flag the root message as having unread messages when a new reply is created" do
      assert !@message.has_unread_replies?
      assert @reply.save
      assert @message.reload.has_unread_replies?
      @message.update_attribute(:has_unread_replies, false)
      reply_to_reply = @reply.build_reply(:body => "All right!",
                                          :sender => @recipient,
                                          :subject => "Feeling chatty")
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
      @message = SendMessage.call(:sender => users(:johan), :recipient => users(:moe),
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

  should "be readable by the sender" do
    message = Message.new(:subject => "Hello", :body => "World")
    message.sender = users(:johan)
    message.recipient = users(:mike)

    assert can_read?(users(:johan), message)
    assert can_read?(users(:mike), message)
    assert !can_read?(users(:moe), message)
  end

  context "marking as read" do
    setup do
      @bob, @alice, @tom = FactoryGirl.build_list(:user, 3)
      @message = FactoryGirl.create(:message, recipients: [@bob, @alice], sender: @tom)
    end

    should "be unread by all the recipients" do
      refute @message.read_by?(@bob)
      refute @message.read_by?(@alice)
    end

    should "be read by sender" do
      assert @message.read_by?(@tom)
    end

    should "be marked as read only by selected recipients" do
      @message.mark_as_read_by_user(@bob)

      @message.reload
      assert @message.read_by?(@bob)
      refute @message.read_by?(@alice)
    end

    should "do nothing if it is marked by the sender" do
      @message.mark_as_read_by_user(@tom)

      assert @message.read_by?(@tom)
    end
  end

  context "marking as archived" do
    setup do
      @bob, @alice, @tom = FactoryGirl.build_list(:user, 3)
      @message = FactoryGirl.create(:message, recipients: [@bob, @alice], sender: @tom)
    end

    should "not by archived by anyone" do
      refute @message.archived_by?(@bob)
      refute @message.archived_by?(@alice)
      refute @message.archived_by?(@tom)
    end

    should "be archived by sender" do
      @message.mark_as_archived_by_user(@tom)

      assert @message.archived_by?(@tom)
      refute @message.archived_by?(@bob)
      refute @message.archived_by?(@alice)
    end

    should "be archived by selected recipients" do
      @message.mark_as_archived_by_user(@bob)

      @message.reload
      refute @message.archived_by?(@tom)
      assert @message.archived_by?(@bob)
      refute @message.archived_by?(@alice)
    end

    should "be reset when a reply is created" do
      @message.mark_as_archived_by_user(@tom)
      @message.save
      reply = @message.build_reply(:body => "Foo", :sender => @bob)
      assert reply.save
      assert !@message.reload.archived_by?(@tom)

      @message.mark_as_archived_by_user(@bob)
      @message.save
      reply_to_reply = reply.build_reply(:body => "Kthxbye", :sender => @tom)
      assert reply_to_reply.save
      assert !@message.reload.archived_by?(@bob)
    end
  end

  context "Thottling" do
    setup do
      Message.destroy_all
      @recipient = FactoryGirl.create(:user)
      @sender = FactoryGirl.create(:user)
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
        10.times{|i|
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
end
