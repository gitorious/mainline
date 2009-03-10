#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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
  has_many :messages, :as => :notifiable, :dependent => :destroy

  after_create :send_notification_if_invited
  attr_accessor :inviter
  
  validates_presence_of :group_id, :user_id, :role_id
  
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
      message = Message.new(:sender => inviter, :recipient => user, :subject => "You have been added to a group", :body => "Welcome", :notifiable => self)
      message.save      
    end
end
