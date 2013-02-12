# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class Group < ActiveRecord::Base
  extend GroupBehavior
  include GroupBehavior::InstanceMethods

  has_many :memberships, :dependent => :destroy
  has_many :members, :through => :memberships, :source => :user

  attr_accessible :name, :user, :description

  Paperclip.interpolates('group_name'){|attachment,style| attachment.instance.name}

  avatar_local_path = '/system/group_avatars/:group_name/:style/:basename.:extension'
  has_attached_file :avatar,
    :default_url  =>'/images/default_group_avatar.png',
    :styles => { :normal => "300x300>", :medium => "64x64>", :thumb => '32x32>', :icon => '16x16>' },
    :url => avatar_local_path,
    :path => ":rails_root/public#{avatar_local_path}"

  def self.human_name
    I18n.t("activerecord.models.group")
  end

  def self.all_participating_in_projects(projects)
    mainline_ids = projects.map do |project|
      project.repositories.mainlines.map{|r| r.id }
    end.flatten
    Committership.groups.find(:all,
      :conditions => { :repository_id => mainline_ids }).map{|c| c.committer }.uniq
  end

  # Finds the most active groups by activity in repositories they're committers in
  def self.most_active(limit = 10, cutoff = 5)
    Rails.cache.fetch("groups:most_active:#{limit}:#{cutoff}", :expires_in => 1.hour) do
      # FIXME: there's a certain element of approximation in here
      find(:all, :joins => [{:committerships => {:repository => :events}}],
        :select => %Q{groups.*, committerships.repository_id,
          repositories.id, events.id, events.target_id, events.target_type,
          count(events.id) as event_count},
        :group => "groups.id",
        :conditions => ["committerships.repository_id = events.target_id and " +
                        "events.target_type = ? AND events.created_at > ?",
                        "Repository", cutoff.days.ago],
        :order => "event_count desc",
        :limit => limit)
    end
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

  def title
    name
  end

  def breadcrumb_parent
    nil
  end

  def member?(user)
    members.include?(user)
  end

  def user_role(candidate)
    return if !candidate || candidate == :false
    membership = memberships.find_by_user_id(candidate.id)
    return unless membership
    membership.role
  end

  def add_member(user, role)
    memberships.create!(:user => user, :role => role)
  end

  def deletable?
    members.count <= 1 && projects.blank?
  end

  def events(page = 1)
    Event.top.paginate(:all, :page => page,
                       :conditions => ["events.user_id in (:user_ids) and events.project_id in (:project_ids)", {
                                         :user_ids => members.map { |u| u.id },
                                         :project_ids => all_related_project_ids,
                                       }],
                       :order => "events.created_at desc",
                       :include => [:user, :project])
  end
end
