# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :target, :polymorphic => true
  belongs_to :project
  has_many   :events, :as => :target, :dependent => :destroy
  after_create :notify_target_if_supported
  after_create :update_state_in_target
  serialize :state_change, Array
  
  is_indexed :fields => ["body"], :include => [{
      :association_name => "user",
      :field => "login",
      :as => "commented_by"
    }]
  
  attr_protected :user_id
    
  validates_presence_of :user_id, :target, :body, :project_id
  
  named_scope :with_shas, proc{|*shas| 
    {:conditions => { :sha1 => shas.flatten }, :include => :user}
  }
  
  NOTIFICATION_TARGETS = [ MergeRequest ]
  
  def deliver_notification_to(another_user)
    message = Message.new({
      :sender => self.user,
      :recipient => another_user,
      :subject => "#{user.title} commented on your #{target.class.human_name.downcase}",
      :body => "#{user.title} commented:\n\n#{body}",
      :notifiable => self.target,
    })
    message.save
  end
  
  def state=(s)
    return if s.blank?
    result = []
    if applies_to_merge_request?
      result << target.status_tag
    end
    result << s
    self.state_change = result
  end
  
  def state_changed_to
    state_change.to_a.last
  end
  
  def state_changed_from
    state_change.to_a.size > 1 ? state_change.first : nil
  end
  
  protected
    def notify_target_if_supported
      if target && NOTIFICATION_TARGETS.include?(target.class)
        return if target.user == user
        deliver_notification_to(target.user)
      end
    end
    
    def applies_to_merge_request?
      MergeRequest === target
    end
    
    def update_state_in_target
      if applies_to_merge_request? and state_change
        target.with_user(user) do
          target.status_tag = state_changed_to if target.resolvable_by?(user)
        end
      end
    end
  
end
