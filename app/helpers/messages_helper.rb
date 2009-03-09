module MessagesHelper
  def message_title(message)
    sender, recipient = if message.recipient == current_user
      [message.sender.fullname, "you"]
    else
      ["You", message.recipient.fullname]
    end
    
    case message.notifiable
    when MergeRequest
      "<strong>#{sender}</strong> sent <strong>#{recipient}</strong> a #{link_to('merge request', [message.notifiable.target_repository.project, message.notifiable.target_repository, message.notifiable])}"
    when Membership 
      %Q{<strong>#{sender}</strong> added <strong>#{recipient}</strong> to the group #{link_to("#{message.notifiable.group.name}", message.notifiable.group)}}
    else
      "<strong>#{sender}</strong> sent <strong>#{recipient}</strong> a #{link_to 'message', message}"
    end
  end
end
