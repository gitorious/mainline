class MessageForwardingProcessor < ApplicationProcessor

  subscribes_to :cc_message

  def on_message(message)
    message_hash = ActiveSupport::JSON.decode(message)
    recipient_id = message_hash['recipient_id']
    sender_id = message_hash['sender_id']
    subject = message_hash['subject']
    body = message_hash['body']
    notifiable_type = message_hash['notifiable_type']
    notifiable_id = message_hash['notifiable_id']
    begin
      recipient = User.find(recipient_id)
      sender = User.find(sender_id)
      notifiable = if !notifiable_type.blank?
        notifiable_type.constantize.find(notifiable_id)
      end
      Mailer.deliver_notification_copy(recipient, sender, subject, body, notifiable)
    rescue ActiveRecord::RecordNotFound
      logger.error("Could not deliver message to #{recipient_id}")
    end
  end
end