# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

require 'test_helper'

class UserMessagesTest < Minitest::Spec
  let(:bob) { FactoryGirl.build(:user, fullname: "Bob") }
  let(:alice) { FactoryGirl.build(:user, fullname: "Alice") }
  let(:tom) { FactoryGirl.build(:user, fullname: "Tom") }

  describe "#all" do
    it "returns all the messages, newest first" do
      last_week = build_message(created_at: 8.days.ago, id: 1)
      this_week = build_message(created_at: 3.days.ago, id: 2, read?: true)
      yesterday = build_message(created_at: 1.day.ago, id: 3, archived?: true)

      messages = bobs_messages(last_week, yesterday, this_week).all

      assert_same(messages, [yesterday, this_week, last_week])
    end

    it "does not return the replies" do
      original_message = build_message(sender: bob, recipient: alice, id: 1)
      reply = build_message(sender: bob, recipient: alice, id: 2, in_reply_to: original_message)

      messages = bobs_messages(original_message, reply).all

      assert_same(messages, [original_message])
    end
  end

  describe "#unread_count" do
    it "returns the count of unread messages" do
      read_message = build_message(id: 1, read?: true)
      unread_message = build_message(id: 2)

      assert_equal 1, bobs_messages(read_message, unread_message).unread_count
    end
  end

  describe "thread_unread?" do
    it "returns false for threads with all messages read" do
      read_message = build_message(id: 1, read?: true)
      unread_message = build_message(id: 2, in_reply_to: read_message)
      another_thread = build_message(id: 3, read?: true)

      messages = bobs_messages(read_message, unread_message, another_thread)
      assert messages.thread_unread?(read_message)
    end

    it "returns true for threads with unread messages" do
      read_message = build_message(id: 1, read?: true)
      unread_message = build_message(id: 2, in_reply_to: read_message, read?: true)
      another_thread = build_message(id: 3)

      messages = bobs_messages(read_message, unread_message, another_thread)
      refute messages.thread_unread?(read_message)
    end
  end

  describe "all_in_thread" do
    it "returns messages from the given thread" do
      read_message = build_message(id: 1, read?: true)
      unread_message = build_message(id: 2, in_reply_to: read_message)
      another_thread = build_message(id: 3, read?: true)

      messages = bobs_messages(read_message, unread_message, another_thread)
      assert_same(messages.all_in_thread(read_message), [read_message, unread_message])
    end
  end

  describe "#sent" do
    it "returns only the messages sent by user, newest first" do
      older_by_bob = build_message(created_at: 8.days.ago, id: 1, sender: bob)
      older_by_alice = build_message(created_at: 3.days.ago, id: 2, sender: alice)
      newer_by_bob = build_message(created_at: 1.day.ago, id: 3, sender: bob)
      newer_by_alice = build_message(created_at: 2.days.ago, id: 4, sender: alice)

      messages = bobs_messages(older_by_bob, newer_by_bob, newer_by_alice, older_by_alice).sent

      assert_same(messages, [newer_by_bob, older_by_bob])
    end
  end

  describe "#inbox" do
    it "returns only top level messages" do
      top_level = build_message(sender: alice, recipient: bob, id: 1)
      reply = build_message(in_reply_to: top_level, sender: alice, recipient: bob, id: 2)

      messages = bobs_messages(top_level, reply).inbox

      assert_same(messages, [top_level])
    end

    it "returns sent messages if they have an unread reply" do
      sent = build_message(sender: bob, recipient: alice, id: 1)
      reply = build_message(in_reply_to: sent, sender: alice, recipient: bob, id: 2, read?: true)
      nested_reply = build_message(in_reply_to: reply, sender: alice, recipient: bob, id: 3, read?: false)

      messages = bobs_messages(sent, reply, nested_reply).inbox

      assert_same(messages, [sent])
    end

    it "does not return archived messages" do
      archived = build_message(sender: alice, recipient: bob, id: 1, archived?: true)

      messages = bobs_messages(archived).inbox

      assert_same(messages, [])
    end

    it "returns archived messages if they have an unread reply" do
      archived = build_message(sender: alice, recipient: bob, id: 1, archived?: true)
      reply = build_message(sender: alice, recipient: bob, in_reply_to: archived, id: 2, read?: false)

      messages = bobs_messages(archived, reply).inbox

      assert_same(messages, [archived])
    end

    it "does not return sent messages" do
      sent = build_message(sender: bob, recipient: alice, id: 1)
      reply = build_message(in_reply_to: sent, sender: alice, recipient: bob, id: 2, read?: true)

      messages = bobs_messages(sent, reply).inbox

      assert_same(messages, [])
    end

    it "sorts the returned messages by last activity, with newest first" do
      old_message = build_message(sender: bob, recipient: alice, id: 1, created_at: 14.days.ago)
      new_reply = build_message(sender: alice, recipient: bob, id: 2, created_at: 2.hours.ago, in_reply_to: old_message)
      new_message = build_message(sender: tom, recipient: bob, id: 3, created_at: 2.days.ago)
      newer_message = build_message(sender: tom, recipient: bob, id: 4, created_at: 1.day.ago)

      messages = bobs_messages(new_message, new_reply, newer_message, old_message).inbox

      assert_same(messages, [old_message, newer_message, new_message])
    end
  end

  describe "#find" do
    it "returns sent messages by id" do
      message = build_message(sender: bob)
      message.save!

      UserMessages.for(bob).find(message.id).must_equal(message)
    end

    it "returns received messages by id" do
      message = build_message(sender: alice, recipients: [bob])
      message.save!

      UserMessages.for(bob).find(message.id).must_equal(message)
    end

    it "raises ActiveRecord::RecordNotFound otherwise" do
      message = build_message(sender: alice, recipients: [tom])
      message.save!

      proc {
        UserMessages.for(bob).find(message.id)
      }.must_raise(ActiveRecord::RecordNotFound)
    end
  end

  def bobs_messages(*messages)
    UserMessages.new(bob, messages)
  end

  def assert_same(actual, expected)
    actual.map(&:id).must_equal(expected.map(&:id))
  end

  def build_message(attrs = {})
    read = attrs.delete(:read?)
    archived = attrs.delete(:archived?)
    message = FactoryGirl.build(:message, attrs)
    message.stubs(:read_by?).with(bob).returns(read)
    message.stubs(:archived_by?).with(bob).returns(archived)
    message
  end
end
