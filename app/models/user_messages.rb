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

class UserMessages
  def self.for(user)
    new(user, Message.involving_user(user))
  end

  def initialize(user, messages)
    @user = user
    @messages = messages
  end

  def find(id)
    messages.find(id)
  end

  def all
    all = remove_replies(messages)
    sort_by_last_activity_time(all)
  end

  def sent
    sent = messages.select { |msg| msg.sender == user }
    sort_by_last_activity_time(sent)
  end

  def inbox
    inbox = remove_replies(messages)
    inbox = remove_sent_with_all_replies_read(inbox)
    inbox = remove_archived_with_all_replies_read(inbox)
    inbox = sort_by_last_activity_time(inbox)
    inbox
  end

  def unread_count
    messages.reject { |m| m.read_by?(user) }.count
  end

  def thread_unread?(message)
    !all_in_thread(message).all? { |msg| msg.read_by?(user) }
  end

  def all_in_thread(message)
    [message] + replies_to(message)
  end

  private

  def remove_replies(messages)
    messages.reject{ |msg| msg.in_reply_to }
  end

  def remove_sent_with_all_replies_read(messages)
    messages.reject{ |msg| msg.sender == user && all_replies_read?(msg) }
  end

  def remove_archived_with_all_replies_read(messages)
    messages.reject { |msg| msg.archived_by?(user) && all_replies_read?(msg) }
  end

  def sort_by_last_activity_time(messages)
    messages.sort_by { |msg| last_activity(msg) }.reverse
  end

  def all_replies_read?(message)
    replies_to(message).all? { |msg| msg.read_by?(user) }
  end

  def replies_to(message)
    children = messages.select { |msg| msg.in_reply_to_id == message.id }
    nested = children.map{ |msg| replies_to(msg) }.flatten
    children + nested
  end

  def last_activity(message)
    created_times = all_in_thread(message).map(&:created_at)
    created_times.max
  end

  attr_reader :user, :messages
end
