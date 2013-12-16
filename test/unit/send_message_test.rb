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

class SendMessageTest < MiniTest::Spec
  describe ".send_message" do
    let(:opts) {{
      sender: User.new,
      recipient: User.new,
      subject: "This is the message subject",
      body: "This is the message body"
    }}

    let(:sent_message) { Message.new }

    before do
      Message.stubs(:build).with(opts).returns(sent_message)
      SendMessage::EmailNotification.stubs(:deliver)
      Message.stubs(:persist).with(sent_message)
    end

    it "saves the message to be viewed online" do
      Message.expects(:persist).with(sent_message)

      send_message
    end

    it "returns the sent message" do
      send_message.must_equal(sent_message)
    end

    it "sends an email with the message" do
      SendMessage::EmailNotification.expects(:deliver).with(sent_message)

      send_message
    end

    def send_message
      SendMessage.call(opts)
    end
  end

  describe SendMessage::EmailNotification do
    include MessagingTestHelper

    let(:sender) { FactoryGirl.build(:user, id: 11) }
    let(:recipient) { FactoryGirl.build(:user, id: 12, wants_email_notifications: true) }
    let(:the_message) { FactoryGirl.build(:message,
                                          id: 256,
                                          sender: sender,
                                          recipient: recipient,
                                          subject: "some subject",
                                          body: "some body",
                                          created_at: Time.parse("2013-11-25 17:31:21")) }

    before do
      clear_message_queue
    end

    def assert_no_messages_published
      assert_messages_published SendMessage::EmailNotification::QUEUE, 0
    end

    it "does not send the email if recipient is the same as sender" do
      the_message.recipient = the_message.sender

      SendMessage::EmailNotification.deliver(the_message)

      assert_no_messages_published
    end

    it "does not send the email if recipient does not want to get email notifications" do
      the_message.recipient.wants_email_notifications = false

      SendMessage::EmailNotification.deliver(the_message)

      assert_no_messages_published
    end

    it "adds notifiable information to the params if possible" do
      the_message.notifiable = FactoryGirl.build(:user, id: 123)

      SendMessage::EmailNotification.deliver(the_message)

      last_message["notifiable_type"].must_equal "User"
      last_message["notifiable_id"].must_equal 123
    end

    it "schedules sending email in background" do
      SendMessage::EmailNotification.deliver(the_message)

      last_message.must_equal(
        "sender_id" => 11,
        "recipient_id" => 12,
        "subject" => "some subject",
        "body" => "some body",
        "created_at" => "2013-11-25T17:31:21Z",
        "identifier" => "email_delivery",
        "message_id" => 256)
    end

    def last_message
      Gitorious::Messaging::TestAdapter.messages_on(SendMessage::EmailNotification::QUEUE).last
    end
  end
end
