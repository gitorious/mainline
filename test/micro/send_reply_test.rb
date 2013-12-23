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

require 'send_reply'
require 'send_message'

class SendReplyTest < MiniTest::Spec
  let(:sender) { :sender }
  let(:reply) { stub(sender: sender) }
  let(:original_message) { stub(read_by?: true, build_reply: reply) }

  before do
    SendMessage.stubs(:send_message).with(reply).returns(reply)
  end

  def send_reply
    SendReply.call(original_message, subject: "Test")
  end

  it "builds the reply and sends it" do
    SendMessage.expects(:send_message).with(reply)

    send_reply
  end

  it "returns the sent reply" do
    send_reply.must_equal reply
  end

  it "marks the original message as read if it wasn't read before" do
    original_message.stubs(:read_by?).with(sender).returns(false)
    original_message.expects(:mark_as_read_by_user).with(sender)

    send_reply.must_equal reply
  end
end
