# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

class PushEventLogger
  PUSH_EVENT_DATA_SEPARATOR = "$"
  def initialize(repository, spec, user)
    @repository = repository
    @spec = spec
    @user = user
  end

  def create_meta_event?
    !@spec.action_update?
  end

  def create_push_event?
    @spec.action_update? && @spec.head?
  end

  def build_meta_event
    Event.new(:action => meta_event_type, :project => @repository.project,
      :user => @user, :target => @repository, :data => @spec.ref_name,
      :body => meta_event_body)
  end

  def build_push_event
    Event.new(:user => @user, :project => @repository.project, :target => @repository,
      :action => Action::PUSH_SUMMARY)
  end

  def create_push_event
    event = build_push_event
    event.data = push_event_data
    event.save
    event
  end
  
  def push_event_data
    [@spec.from_sha.sha, @spec.to_sha.sha, @spec.ref_name, calculate_commit_count.to_s].join(PUSH_EVENT_DATA_SEPARATOR)
  end

  def calculate_commit_count
    lines = @repository.git.git.log({:pretty => "oneline"}, [@spec.from_sha.sha, @spec.to_sha.sha].join(".."))
    lines.split("\n").size
  end

  private
  def meta_event_type
    return head_meta_event_type if @spec.head?
    tag_meta_event_type
  end

  def head_meta_event_type
    @spec.action_create? ? Action::CREATE_BRANCH : Action::DELETE_BRANCH
  end

  def tag_meta_event_type
    @spec.action_create? ? Action::CREATE_TAG : Action::DELETE_TAG
  end

  def meta_event_body
    return "New branch" if @spec.head?
    tag_meta_body
  end

  def tag_meta_body
    @spec.action_create? ? "Created tag #{@spec.ref_name}" : "Deleted tag #{@spec.ref_name}"
  end
end
