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
  
  context 'The state machine' do
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

    should 'set a default subject when replying to a message' do
      assert_equal("Re: #{@message.subject}", @reply.subject)
    end

    should 'flag which message the reply relates to' do
      assert_equal @message, @reply.in_reply_to
    end
  end
  
  context 'Email notifications' do
    should_eventually "deliver email notifications after create if the recipient wants them"
    should_eventually "skip email delivery after create if the recipient doesn't want them"
  end
  
  context 'Mass email delivery' do
    should_eventually 'create n messages when supplying several recipients'
  end
end
