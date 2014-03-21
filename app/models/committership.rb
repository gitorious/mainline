# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
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

class Committership < ActiveRecord::Base
  CAN_REVIEW = 1 << 4
  CAN_COMMIT = 1 << 5
  CAN_ADMIN = 1 << 6

  PERMISSION_TABLE = {
    :review => CAN_REVIEW,
    :commit => CAN_COMMIT,
    :admin => CAN_ADMIN
  }

  belongs_to :committer, :polymorphic => true
  belongs_to :repository
  belongs_to :creator, :class_name => "User"
  has_many :messages, :as => :notifiable

  attr_accessible :committer, :repository, :creator, :creator_id

  after_create :notify_repository_owners
  after_create :add_new_committer_event
  before_destroy :nullify_messages

  scope :groups, :conditions => { :committer_type => "Group" }
  scope :users,  :conditions => { :committer_type => "User" }
  scope :reviewers, :conditions => ["(permissions & ?) != 0", CAN_REVIEW]
  scope :committers, :conditions => ["(permissions & ?) != 0", CAN_COMMIT]
  scope :admins, :conditions => ["(permissions & ?) != 0", CAN_ADMIN]

  def uniq?
    committership = Committership.where(committer_type: committer_type,
                                        repository_id: repository_id,
                                        committer_id: committer_id).first

    committership.nil? || committership == self
  end

  def permission_mask_for(*perms)
    perms.inject(0) do |memo, perm_symbol|
      memo | PERMISSION_TABLE[perm_symbol]
    end
  end

  def build_permissions(*perms)
    perms = perms.flatten.compact.map{|p| p.to_sym }
    self.permissions = permission_mask_for(*perms)
  end

  def permitted?(wants_to)
    raise "unknown permission: #{wants_to.inspect}" if !PERMISSION_TABLE[wants_to]
    (self.permissions & PERMISSION_TABLE[wants_to]) != 0
  end

  def reviewer?
    permitted?(:review)
  end

  def committer?
    permitted?(:commit)
  end

  def admin?
    permitted?(:admin)
  end

  def permission_list
    PERMISSION_TABLE.keys.select{|perm| permitted?(perm) }
  end

  def title
    new_record? ? "New collaborator" : "Collaborator"
  end

  # returns all the users in this committership, eg if it's a group it'll
  # return an array of the group members, otherwise a single-member array of
  # the user
  def members
    case committer
    when Group
      committer.members
    when LdapGroup
      committer.members
    else
      [committer]
    end
  end

  def add_removed_committer_event(user)
    repository.project.create_event(Action::REMOVE_COMMITTER, repository,
                                    user, committer.title)
  end

  protected
  def notify_repository_owners
    return unless creator
    SendMessage.call(
      :sender => creator,
      :recipients => repository.owners,
      :subject => I18n.t("committership.notification_subject"),
      :body => I18n.t("committership.notification_body", {
        :inviter => creator.title,
        :user => committer.title,
        :repository => repository.name,
        :project => repository.project.title
      }),
      :notifiable => self)
  end

  def add_new_committer_event
    repository.project.create_event(Action::ADD_COMMITTER, repository,
                                    creator, committer.title)
  end

  def nullify_messages
    messages.update_all({:notifiable_id => nil, :notifiable_type => nil})
  end
end
