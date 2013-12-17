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
      this_week = build_message(created_at: 3.days.ago, id: 2)
      yesterday = build_message(created_at: 1.day.ago, id: 3)

      messages = bobs_messages(last_week, yesterday, this_week).all

      assert_same(messages, [yesterday, this_week, last_week])
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
    FactoryGirl.build(:message, attrs)
  end
end
