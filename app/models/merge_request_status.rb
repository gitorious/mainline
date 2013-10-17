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

class MergeRequestStatus < ActiveRecord::Base
  COLOR_REGEXP = /^#[0-9a-f]{3}{1,2}$/i
  belongs_to :project

  validates_presence_of :project, :state, :name
  validates_format_of :color, :with => COLOR_REGEXP,
    :message => "should be hex encoded (eg '#cccccc', like in CSS)", :allow_blank => true

  before_save :synchronize_merge_request_statuses

  def self.default
    where(:default => true).first
  end

  def self.create_defaults_for_project(project)
    project.merge_request_statuses.create!({
        :name => "Open",
        :state => MergeRequest::STATUS_OPEN,
        :color => "#408000",
        :default => true
      })
    project.merge_request_statuses.create!({
        :name => "Closed",
        :state => MergeRequest::STATUS_CLOSED,
        :color => "#AA0000"
      })
  end

  def self.default_states
    {
      "Open" => MergeRequest::STATUS_OPEN,
      "Closed" => MergeRequest::STATUS_CLOSED
    }
  end

  def self.open?(name)
    default_states[name] == MergeRequest::STATUS_OPEN
  end

  def open?
    state == MergeRequest::STATUS_OPEN
  end

  def closed?
    state == MergeRequest::STATUS_CLOSED
  end

  # Updates the status of all the merge requests for the mainlines in
  # the project who has the same status_tag as this MergeRequestStatus
  def synchronize_merge_request_statuses
    if state_changed? || name_changed?
      # FIXME: doing it like this is a bit inefficient...
      merge_requests = self.project.repositories.mainlines.map(&:merge_requests).flatten
      old_name = (name_changed? ? name_change.first : name)
      merge_requests.select{|mr| mr.status_tag.to_s == old_name }.each do |mr|
        mr.status = self.state if state_changed?
        mr.status_tag = self.name if name_changed?
        mr.save!
      end
    end
  end
end
