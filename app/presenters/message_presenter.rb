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

require 'forwardable'

class MessagePresenter < Struct.new(:message, :viewer, :view_context)
  extend Forwardable
  def_delegators :message, :id, :to_key, :body, :created_at, :subject, :notifiable, :to_param

  def self.model_name
    Message.model_name
  end

  def message_class
    state = message.read_by?(viewer) ? "read" : "unread"
    "#{state} #{css_class} message full"
  end

  def messages_in_thread
    messages = user_messages.all_in_thread(message)
    messages.map { |m| MessagePresenter.new(m, viewer, view_context) }
  end

  def number_of_messages_in_thread
    messages_in_thread.count
  end

  def thread_class
    state = user_messages.thread_unread?(message) ? "unread" : "read"
    "#{state} #{css_class}"
  end

  def sender_and_recipients
    ([sender] + recipients).to_sentence.html_safe
  end

  def unread_by_viewer?
    !message.read_by?(viewer) && message.recipients.include?(viewer)
  end

  def repliable?
    (message.sender != viewer) && message.replies_enabled?
  end

  def message_title
    case message.notifiable
    when MergeRequest
      merge_request_title
    when Membership
      membership_title
    when Committership
      committership_title
    else
      default_title
    end.html_safe
  end

  def thread_title
    message.subject || I18n.t("views.messages.new")
  end

  def sender_avatar
    if message.replies_enabled?
      v.avatar_from_email(message.sender.email, :size => 32)
    else
      v.image_tag("default_face.gif", :size => "32x32")
    end
  end

  private
  alias :v :view_context

  def involved_person_name(user)
    return "me" if user == viewer
    return "[removed]" if user.nil?
    v.link_to(user.title, user)
  end

  def merge_request_title
    msg_link = v.link_to('merge request', [message.notifiable.target_repository.project,
                                           message.notifiable.target_repository,
                                           message.notifiable])
    "From <strong>#{sender}</strong> to #{formatted_recipients}, about a #{msg_link}"
  end

  def membership_title
    %Q{<strong>#{sender}</strong> added #{formatted_recipients} to the } +
      %Q{team #{v.link_to("#{message.notifiable.group.name}", message.notifiable.group)}}
  end

  def committership_title
    committership = message.notifiable
    user_link = v.link_to(committership.committer.title, [committership.repository.project,
                                                          committership.repository,
                                                          :committerships])
    %Q{<strong>#{sender}</strong> added #{user_link} as committer in } +
      %Q{<strong>#{committership.repository.name}</strong>}
  end

  def default_title
    "#{v.link_to('message', message)} from <strong>#{sender}</strong> to #{formatted_recipients}"
  end

  def user_messages
    @user_messages ||= UserMessages.for(viewer)
  end

  def sender
    involved_person_name(message.sender)
  end

  def recipients
    message.recipients.map {|user| involved_person_name(user) }
  end

  def formatted_recipients
    recipients.map { |r| "<strong>#{r}</strong>".html_safe }.to_sentence
  end

  def css_class
    (notifiable || message).class.name.underscore
  end

end
