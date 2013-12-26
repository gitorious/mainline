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

require "builder"

class Message < ActiveRecord::Base
  include RecordThrottling
  include Gitorious::Messaging::Publisher

  belongs_to :notifiable, :polymorphic => true
  belongs_to :sender, :class_name => "User", :foreign_key => :sender_id
  belongs_to :in_reply_to, :class_name => 'Message', :foreign_key => :in_reply_to_id
  belongs_to :root_message, :class_name => 'Message', :foreign_key => :root_message_id
  before_create :flag_root_message_if_required

  has_many :replies, :class_name => 'Message', :foreign_key => :in_reply_to_id

  has_many :message_recipients
  has_and_belongs_to_many :recipients,
    :class_name => "User",
    :association_foreign_key => :recipient_id

  validates_presence_of :subject, :body
  validates_presence_of :recipients, :sender, :allow_blank => false

  throttle_records(:create, {
      :limit => 10,
      :actor => proc { |msg| msg.sender },
      :counter => proc { where("created_at > ?", 1.day.ago).count },
      :conditions => proc { |sender| { :sender_id => sender.id, :notifiable_type => nil } },
      :timeframe => 15.minutes
    })

  def self.build(opts = {})
    new(opts)
  end

  def self.persist(message)
    message.save!
  end

  def self.involving_user(user)
    includes(:message_recipients).
      where('sender_id = ? OR messages_users.recipient_id = ?', user, user)
  end

  def build_reply(options={})
    new_sender = options.fetch(:sender)
    reply_options = {:sender => new_sender, :recipients => [sender], :subject => "Re: #{subject}"}.with_indifferent_access
    reply = Message.new(reply_options.merge(options))
    reply.in_reply_to = self
    reply.root_message_id = root_message_id || id
    return reply
  end

  def recipient
    recipients.first
  end

  def recipient=(user)
    self.recipients = [user] if user
  end

  def recipient_logins
    recipients.map(&:login).join(', ')
  end

  def recipient_logins=(str)
    logins = str.to_s.split(/[\.,\s]/).map(&:strip)
    self.recipients = User.where(login: logins)
  end

  def replies_enabled?
    notifiable.nil?
  end

  def mark_as_read_by_user(candidate)
    return if candidate == sender
    message_recipient(candidate).read!
  end

  def mark_thread_as_read_by_user(user)
    UserMessages.for(user).all_in_thread(self).each do |msg|
      msg.mark_as_read_by_user(user)
    end
  end

  def read_by?(user)
    return true if user == sender
    message_recipient(user).read?
  end

  def archived_by?(user)
    return archived_by_sender if user == sender
    message_recipient(user).archived?
  end

  def mark_as_archived_by_user(user)
    if user == sender
      self.archived_by_sender = true
    else
      message_recipient(user).archive!
    end
  end

  def touch!
    touch(:last_activity_at)
  end

  protected

  def message_recipient(user)
    message_recipients.detect { |r| r.recipient == user }
  end

  def flag_root_message_if_required
    self.last_activity_at = current_time_from_proper_timezone
    if root_message
      if root_message.sender == recipient
        root_message.has_unread_replies = true
        root_message.archived_by_sender = false
      else
        root_message.message_recipients.each(&:unarchive!)
      end
      root_message.touch!
      root_message.save
    end
  end
end
