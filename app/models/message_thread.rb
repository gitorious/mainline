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
class MessageThread
  attr_reader :message
  include Enumerable

  def initialize(options)
    subject    = options[:subject]
    body       = options[:body]
    sender     = options[:sender]
    recipient_logins = options[:recipients]

    @message = Message.new(:sender => sender,
                           :subject => subject,
                           :body => body,
                           :recipient_logins => recipient_logins)

    Rails.logger.debug("MessageThread for #{recipient_logins}")
  end

  def each
    messages.each{|m| yield m}
  end

  def messages
    [message]
  end

  def size
    messages.size
  end

  def title
    "#{size} " + ((size == 1) ? 'message' : 'messages')
  end

  def validated_message
    message.valid?
    message
  end

  def recipients
    message.recipient_logins.split(', ')
  end

  def sender
    message.sender
  end

  def save!
    SendMessage.send_message(message)
  end
end
