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

module MessagesHelper
  def sender_and_recipient_display(message)
    sender, recipients = sender_and_recipients_for(message)
    all = [sender] + recipients
    all.to_sentence.html_safe
  end

  def involved_person_name(user)
    return "me" if user == current_user
    return "[removed]" if user.nil?
    link_to(h(user.title), user)
  end

  def sender_and_recipients_for(message)
    sender = involved_person_name(message.sender)
    recipients = message.recipients.map {|user| involved_person_name(user) }

    [sender, recipients]
  end

  def other_party(message,user)
    message.recipient == user ? message.sender : message.recipient
  end

  def message_title(message)
    sender, recipients = sender_and_recipients_for(message)
    formatted_recipients = recipients.map { |r| "<strong>#{r}</strong>".html_safe }.to_sentence

    case message.notifiable
    when MergeRequest
      msg_link = link_to('merge request', [message.notifiable.target_repository.project,
                                           message.notifiable.target_repository,
                                           message.notifiable])
      "From <strong>#{sender}</strong> to #{formatted_recipients}, about a #{msg_link}"
    when Membership
      %Q{<strong>#{sender}</strong> added #{formatted_recipients} to the } +
        %Q{team #{link_to("#{message.notifiable.group.name}", message.notifiable.group)}}
    when Committership
      committership = message.notifiable
      user_link = link_to(committership.committer.title, [committership.repository.project,
                                                          committership.repository,
                                                          :committerships])
      %Q{<strong>#{sender}</strong> added #{user_link} as committer in } +
        %Q{<strong>#{committership.repository.name}</strong>}
    else
      "#{link_to('message', message)} from <strong>#{sender}</strong> to #{formatted_recipients}"
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
