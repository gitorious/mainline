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
class MessageForwardingProcessor < ApplicationProcessor

  subscribes_to :cc_message

  def on_message(message)
    verify_connections!
    message_hash = ActiveSupport::JSON.decode(message)
    logger.debug("#{self.class.name} on message #{hash.inspect}")
    recipient_id = message_hash['recipient_id']
    sender_id = message_hash['sender_id']
    subject = message_hash['subject']
    body = message_hash['body']
    notifiable_type = message_hash['notifiable_type']
    notifiable_id = message_hash['notifiable_id']
    message_id = message_hash['message_id']
    begin
      recipient = User.find(recipient_id)
      sender = User.find(sender_id)
      notifiable = if !notifiable_type.blank?
        notifiable_type.constantize.find(notifiable_id)
      end
      logger.info("#{self.class.name} sending Message:#{message_id.inspect} to #{recipient.login} from #{sender.login}")
      Mailer.deliver_notification_copy(recipient, sender, subject, body, notifiable, message_id)
    rescue ActiveRecord::RecordNotFound
      logger.error("Could not deliver message to #{recipient_id}")
    end
  end
end
