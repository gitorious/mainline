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

class Group < ActiveRecord::Base
  has_many :committerships, :as => :committer
  has_many :participated_repositories, :through => :committerships, 
    :source => :repository, :class_name => 'Repository'  
  belongs_to :creator, :class_name => "User", :foreign_key => "user_id"
  has_many :memberships
  has_many :members, :through => :memberships, :source => :user
  has_many :repositories, :as => :owner, :conditions => { :kind => Repository::KIND_PROJECT_REPO }
  has_many :projects, :as => :owner
  
  attr_protected :public, :role_id, :user_id
  
  NAME_FORMAT = /[a-z0-9\-]+/.freeze
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :name, :with => /^#{NAME_FORMAT}$/, 
    :message => "Must be alphanumeric, and optional dash"
    
  def self.human_name
    I18n.t("activerecord.models.group")
  end
  
  def all_related_project_ids
    all_project_ids = projects.map{|p| p.id }
    all_project_ids << repositories.map{|r| r.project_id }
    all_project_ids << committerships.map{|p| p.repository.project_id }
    all_project_ids.flatten!.uniq!
    all_project_ids
  end
  
  def to_param
    name
  end
  
  def to_param_with_prefix
    "+#{to_param}"
  end
  
  def title
    name
  end
  
  def breadcrumb_parent
    nil
  end
  
  # is this +user+ a member of this group?
  def member?(user)
    members.include?(user)
  end
  
  # returns the Role of +user+ in this group
  def role_of_user(candidate)
    if !candidate || candidate == :false
      return
    end
    membership = memberships.find_by_user_id(candidate.id)
    return unless membership
    membership.role
  end
  
  # is +candidate+ an admin in this group?
  def admin?(candidate)
    role_of_user(candidate) == Role.admin
  end
  
  # is +candidate+ a committer (or admin) in this group?
  def committer?(candidate)
    [Role.admin, Role.committer].include?(role_of_user(candidate))
  end
  
  # Adds +a_user+ as a member to this group with a role of +a_role+
  def add_member(a_user, a_role)
    memberships.create!(:user => a_user, :role => a_role)
  end
  
  def create_event(*args)
    if project
      project.create_event(*args)
    end
  end
end
