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
module SendMessage
  def self.call(opts = {})
    message = Message.build(opts)
    send_message(message)
  end

  def self.send_message(message)
    Message.persist(message)
    EmailNotification.deliver(message)
    message
  end

  class EmailNotification
    QUEUE = "/queue/GitoriousEmailNotifications"

    def self.deliver(message)
      message.recipients.each do |recipient|
        new(message, recipient).deliver
      end
    end

    def initialize(message, recipient)
      @message = message
      @recipient = recipient
    end

    def deliver
      return unless recipient_wants_email_notifications?
      return if recipient_is_the_sender?

      enqueue
    end

    private

    def recipient_wants_email_notifications?
      recipient.wants_email_notifications?
    end

    def recipient_is_the_sender?
      recipient == message.sender
    end

    def job_params
      {
        sender_id: message.sender.id,
        recipient_id: recipient.id,
        subject: message.subject,
        body: message.body,
        created_at: message.created_at,
        identifier: "email_delivery",
        message_id: message.id
      }.merge(notifiable_params)
    end

    def notifiable_params
      notifiable = message.notifiable

      return {} unless notifiable && notifiable.id

      { notifiable_type: notifiable.class.name,
        notifiable_id: notifiable.id }
    end

    def enqueue
      publish(QUEUE, job_params)
    end

    attr_reader :message, :recipient

    include Gitorious::Messaging::Publisher
  end

  InvalidMessage = ActiveRecord::RecordInvalid
end
