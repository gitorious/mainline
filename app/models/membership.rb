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

class Membership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user
  belongs_to :role
  has_many :messages, :as => :notifiable
  before_validation_on_update :dont_demote_group_creator
  before_destroy :dont_delete_group_creator
  before_destroy :nullify_messages

  after_create :send_notification_if_invited
  attr_accessor :inviter
  
  validates_presence_of :group_id, :user_id, :role_id
  
  validates_uniqueness_of :user_id, :scope => :group_id, :message => 'is already member of this team'
  
  def breadcrumb_parent
    Breadcrumb::Memberships.new(group)
  end
  
  def title
    "Member"
  end
  
  def self.build_invitation(inviter, options)
    result = new(options.merge(:inviter => inviter))
    return result
  end
  
  
  protected
    def send_notification_if_invited
      if inviter
        send_notification
      end
    end
    
    def send_notification
      message = Message.new({
        :sender => inviter,
        :recipient => user,
        :subject => I18n.t("membership.notification_subject"),
        :body => I18n.t("membership.notification_body", {
          :inviter => inviter.title,
          :group => group.title,
          :role => role.admin? ? 'administrator' : 'member'
        }),
        :notifiable => self
      })
      message.save      
    end
    
    def dont_demote_group_creator
      if user == group.creator and role == Role.member
        errors.add(:role, "The group creator cannot be denoted")
        return false
      end
    end
    
    def dont_delete_group_creator
      return user != group.creator
    end
    
    def nullify_messages
      messages.update_all({:notifiable_id => nil, :notifiable_type => nil})
    end
end
