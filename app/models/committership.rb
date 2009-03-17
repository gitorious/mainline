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

class Committership < ActiveRecord::Base
  belongs_to :committer, :polymorphic => true
  belongs_to :repository
  belongs_to :creator, :class_name => 'User'
  
  validates_presence_of :committer_id, :committer_type, :repository_id
  after_create :notify_repository_owners
  after_create :add_new_committer_event
  after_destroy :add_removed_committer_event
  
  named_scope :groups, :conditions => { :committer_type => "Group" }
  named_scope :users,  :conditions => { :committer_type => "User" }  
  
  def breadcrumb_parent
    Breadcrumb::Committerships.new(repository)
  end
  
  def title
    new_record? ? "New committer" : "Committer"
  end
  
  # returns all the users in this committership, eg if it's a group it'll 
  # return an array of the group members, otherwise a single-member array of
  # the user
  def members
    case committer
    when Group
      committer.members
    else
      [committer]
    end
  end
  
  protected
    def notify_repository_owners
      return unless creator
      recipients = repository.owners
      recipients.each do |r|
        message = Message.new(:sender => creator, :recipient => r, :subject => "A new committer has been added", :body => "The more, the merrier", :notifiable => self)
        message.save
      end
    end
    
    def add_new_committer_event
      repository.project.create_event(Action::ADD_COMMITTER, repository, 
                                      creator, committer.title)
    end
    
    def add_removed_committer_event
      repository.project.create_event(Action::REMOVE_COMMITTER, repository, 
                                      creator, committer.title)
    end
end
