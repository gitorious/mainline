# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class MessageForwardingProcessorTest < ActiveSupport::TestCase

  def setup
    @processor = MessageForwardingProcessor.new
    @sender = users(:moe)
    @recipient = users(:mike)
    @message = messages(:johans_message_to_moe)
  end

  def teardown
    @processor = nil
  end

  should 'increment the number of deliveries by one when receiving a message' do
    json_hash = {
      :sender_id => @sender.id,
      :recipient_id => @recipient.id,
      :subject => "Hello world",
      :body => "This is just ridiculous",
      :message_id => @message.id
    }

    assert_incremented_by(ActionMailer::Base.deliveries, :size, 1) do
      @processor.consume(json_hash.to_json)
    end
  end

  should 'not deliver email if sender or recipient cannot be found' do
    json_hash = {
      :sender_id => @sender.id,
      :recipient_id => @recipient.id + 999,
      :subject => "Hello world",
      :body => "This is just ridiculous",
      :message_id => @message.id
    }

    assert_incremented_by(ActionMailer::Base.deliveries, :size, 0) do
      @processor.consume(json_hash.to_json)
    end
  end
end
