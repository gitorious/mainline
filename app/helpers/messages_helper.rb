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
module MessagesHelper
  def sender_and_recipient_display(message)
    sender_and_recipient_for(message).collect(&:capitalize).join(",")
  end
  
  def sender_and_recipient_for(message)
    if message.recipient == current_user
      [h(message.sender_name), "me"]
    else
      ["me", h(message.recipient.title)]
    end
  end
  
  def message_title(message)
    sender, recipient = sender_and_recipient_for(message)
    
    case message.notifiable
    when MergeRequest
      "From <strong>#{sender}</strong> to <strong>#{recipient}</strong>, about a #{link_to('merge request', [message.notifiable.target_repository.project, message.notifiable.target_repository, message.notifiable])}"
    when Membership 
      %Q{<strong>#{sender}</strong> added <strong>#{recipient}</strong> to the team #{link_to("#{message.notifiable.group.name}", message.notifiable.group)}}
    when Committership
      committership = message.notifiable
      %Q{<strong>#{sender}</strong> added #{link_to(committership.committer.title, [committership.repository.project,committership.repository,:committerships])} as committer in <strong>#{committership.repository.name}</strong>}
    else
      "#{link_to('message', message)} from <strong>#{sender}</strong> to <strong>#{recipient}</strong>"
    end
  end

  def sender_avatar(message)
    if message.replies_enabled?
      avatar_from_email(message.sender.email, :size => 32)
    else
      image_tag("default_face.gif", :size => "32x32")
    end
  end
end
