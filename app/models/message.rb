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
class Message < ActiveRecord::Base
  include RecordThrottling
  include Gitorious::Messaging::Publisher
  
  belongs_to :notifiable, :polymorphic => true
  belongs_to :sender, :class_name => "User", :foreign_key => :sender_id
  belongs_to :recipient, :class_name => "User", :foreign_key => :recipient_id
  belongs_to :in_reply_to, :class_name => 'Message', :foreign_key => :in_reply_to_id
  belongs_to :root_message, :class_name => 'Message', :foreign_key => :root_message_id
  after_create :send_email_notification_if_required
  before_create :flag_root_message_if_required
  
  has_many :replies, :class_name => 'Message', :foreign_key => :in_reply_to_id
  
  validates_presence_of :subject, :body
  validates_presence_of :recipient, :sender
  
  throttle_records :create, :limit => 5,
    :counter => proc{|msg|
      msg.sender.sent_messages.count(:all,
        :conditions => ["created_at > ?", 1.day.ago])
    },
    :conditions => proc{|msg| {:sender_id => msg.sender.id, :notifiable_type => nil} },
    :timeframe => 1.day

  state_machine :aasm_state, :initial => :unread do
    event :read do
      transition :unread => :read
    end
  end
  
  def build_reply(options={})
    reply_options = {:sender => recipient, :recipient => sender, :subject => "Re: #{subject}"}.with_indifferent_access
    reply = Message.new(reply_options.merge(options))
    reply.in_reply_to = self
    reply.root_message_id = root_message_id || id
    return reply
  end
  
  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.message do
      xml.tag!(:id, to_param)
      xml.tag!(:subject, subject)
      xml.tag!(:body, body)
      xml.tag!(:read, read?)
      xml.tag!(:notifiable, notifiable.class.name) if notifiable
      xml.tag!(:description, description)
      xml.tag!(:recipient_name, recipient.title)
      xml.tag!(:sender_name, sender.title)
    end
  end

  def recipient_name
    recipient.title
  end
  
  def sender_name
    if notifiable
      "Gitorious"
    else
      sender.title
    end
  end
  
  def breadcrumb_parent
    in_reply_to || Breadcrumb::Messages.new(sender)
  end

  def replies_enabled?
    notifiable.nil?
  end
  
  def display_state_for(a_user)
    if a_user == sender
      return "not_mine"
    end
    if unread?
      return "unread"
    end
    return "read"
  end
  
  def description
    (notifiable || self).class.name.titleize.downcase
  end
  
  def css_class
    (notifiable || self).class.name.underscore
  end

  # Used in breadcrumbs
  def title
    subject || I18n.t("views.messages.new")
  end
  
  def breadcrumb_css_class
    "new_email"
  end
  
  def number_of_messages_in_thread
    messages_in_thread.size
  end
  
  def recipients=(recipients_string)
    @recipients = recipients_string
  end
  
  def recipients
    @recipients || recipient.try{login}
  end
  
  def messages_in_thread
    replies.inject([self]) do |result, message|
      result << message.messages_in_thread
    end.flatten
  end
  
  def unread_messages_in_thread
    messages_in_thread.select(&:unread?)
  end
  
  def unread_messages?
    !unread_messages_in_thread.blank?
  end
  
  # Displays whether there are any unread messages in this message's thread for +a_user+
  def aasm_state_for_user(a_user)
    if unread_messages_in_thread.any?{|msg|msg.recipient == a_user}
      "unread"
    else
      "read"
    end
  end

  def readable_by?(candidate)
    [self.sender, self.recipient].include?(candidate)
  end

  def mark_as_read_by_user(candidate)
     self.read if self.recipient == candidate
  end

  def mark_thread_as_read_by_user(a_user)
    self.messages_in_thread.each do |msg|
      msg.mark_as_read_by_user(a_user)
    end
  end
  
  def archived_by(a_user)
    if a_user == sender
      self.archived_by_sender = true
    end
    if a_user == recipient
      self.archived_by_recipient = true
    end
  end

  def touch!
    touch(:last_activity_at)
  end
  
  protected
    def send_email_notification_if_required
      if recipient.wants_email_notifications? and (recipient != sender)
        schedule_email_delivery
      end
    end
    
    def schedule_email_delivery
      options = {
        :sender_id => sender.id,
        :recipient_id => recipient.id,
        :subject => subject,
        :body => body,
        :created_at => created_at,
        :identifier => "email_delivery",
        :message_id => self.id,
      }
      if notifiable && notifiable.id
        options.merge!({
            :notifiable_type => notifiable.class.name,
            :notifiable_id => notifiable.id,
        })
      end

      publish("/queue/GitoriousEmailNotifications", options)
    end
    
    def flag_root_message_if_required
      self.last_activity_at = current_time_from_proper_timezone
      if root_message
        if root_message.sender == recipient
          root_message.has_unread_replies = true
          root_message.archived_by_sender = false
        else
          root_message.archived_by_recipient = false
        end
        root_message.touch!
        root_message.save
      end
    end
end
