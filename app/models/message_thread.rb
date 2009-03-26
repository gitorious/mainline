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
  attr_reader :recipients, :sender
  include Enumerable

  def initialize(options)
    @subject    = options[:subject]
    @body       = options[:body]
    @sender     = options[:sender]
    @recipients = extract_recipients(options[:recipients])
    RAILS_DEFAULT_LOGGER.debug("MessageThread for #{@recipients.join(',')}")
  end
  
  def each
    messages.each{|m| yield m}
  end
  
  def extract_recipients(recipient_string)
    recipient_string.split(/[,\s\.]/).map(&:strip)    
  end
  
  def messages
    @messages ||= initialize_messages
  end
  
  def size
    messages.size
  end
  
  def title
    "#{size} " + ((size == 1) ? 'message' : 'messages')
  end
  
  # Returns a message object, used in views etc
  def message
    Message.new(:sender => @sender, :subject => @subject, :body => @body, :recipients => recipients.join(','))
  end
  
  def save
    all_ok = nil
    messages.each{|msg|
      all_ok = true if all_ok.nil?
      all_ok = false unless msg.save
    }
    return all_ok
  end
  
  protected
    def initialize_messages
      recipients.inject([]) do |result, recipient_name|
        result << Message.new(:sender => @sender, :subject => @subject, :body => @body, :recipient => User.find_by_login(recipient_name))
      end
    end
end