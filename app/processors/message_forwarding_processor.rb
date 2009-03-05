class MessageForwardingProcessor < ApplicationProcessor

  subscribes_to :cc_message

  def on_message(message)
    message_hash = ActiveSupport::JSON.decode(message)
    recipient_id = message_hash['recipient_id']
    sender_id = message_hash['sender_id']
    subject = message_hash['subject']
    body = message_hash['body']
    begin
      recipient = User.find(recipient_id)
      sender = User.find(sender_id)
      Mailer.deliver_notification_copy(recipient, sender, subject, body)
    rescue ActiveRecord::RecordNotFound
      logger.error("Could not deliver message to #{recipient_id}")
    end
  end
end