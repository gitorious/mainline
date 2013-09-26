# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
require 'gitorious/authorization'

class ProjectProposal < ActiveRecord::Base
  extend Gitorious::Authorization
  belongs_to :creator, :class_name => "User", :foreign_key => "user_id"
  validates_presence_of :title, :user_id, :description
  validates_uniqueness_of :title
  has_many :messages, :as => :notifiable

  def name_clashes_with_existing_project?
    !Project.find_by_title(self.title).nil?
  end

  def reject
    self.destroy
  end

  def approve
    project = Project.new({
                :title => self.title,
                :slug => self.title.gsub(" ", "-"),
                :description => self.description,
                :user => self.creator,
                :owner => self.creator
              })
    project.save!
    self.destroy
    return project
  end

  def self.required?(user)
    enabled? && !site_admin?(user)
  end

  def self.enable; @enabled = true; end
  def self.disable; @enabled = false; end
  def self.enabled?; @enabled; end
end
