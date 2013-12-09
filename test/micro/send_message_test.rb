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

require 'fast_test_helper'

require 'send_message'

class SendMessageTest < MiniTest::Spec
  let(:opts) {{
    sender: User.new,
    recipient: User.new,
    subject: "This is the message subject",
    body: "This is the message body"
  }}

  let(:sent_message) { Message.new }

  before do
    Message.stubs(:build).with(opts).returns(sent_message)
    sent_message.stubs(:deliver_email)
    Message.stubs(:persist).with(sent_message)
  end

  def send_message
    SendMessage.call(opts)
  end

  it "saves the message to be viewed online" do
    Message.expects(:persist).with(sent_message)

    send_message
  end

  it "returns the sent message" do
    send_message.must_equal(sent_message)
  end

  it "sends an email with the message" do
    sent_message.expects(:deliver_email)

    send_message
  end
end
