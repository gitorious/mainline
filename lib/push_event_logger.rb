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

  def initialize(repository, spec, user, pushed_at = nil)
    @repository = repository
    @spec = spec
    @user = user
    @pushed_at = pushed_at
  end

  def create_meta_event?
    !@spec.action_update?
  end

  def create_push_event?
    (@spec.action_update? || @spec.action_create?) && @spec.head?
  end

  def build_meta_event
    Event.new(:action => meta_event_type, :project => @repository.project,
      :user => @user, :target => @repository, :data => @spec.ref_name,
      :body => meta_event_body, :created_at => @pushed_at)
  end

  def create_meta_event
    event = build_meta_event
    event.save!
    event
  end

  def build_push_event
    Event.new(:user => @user, :project => @repository.project, :target => @repository,
      :action => Action::PUSH_SUMMARY, :created_at => @pushed_at)
  end

  def create_push_event
    event = build_push_event
    event.data = push_event_data
    event.save
    event
  end

  def push_commit_extractor
    @push_commit_extractor ||= PushCommitExtractor.new(@repository.full_repository_path, @spec)
  end

  def push_event_data
    [calculate_first_commit(@spec).oid, @spec.to_sha.sha, @spec.ref_name, calculate_commit_count.to_s].join(PUSH_EVENT_DATA_SEPARATOR)
  end

  def calculate_first_commit(spec)
    push_commit_extractor.newest_known_commit
  end

  def self.parse_event_data(data_string)
    start_sha, end_sha, branch_name, commit_count = data_string.split(PUSH_EVENT_DATA_SEPARATOR)
    {
      :start_sha       => start_sha,
      :start_sha_short => start_sha[0,7],
      :end_sha         => end_sha,
      :end_sha_short   => end_sha[0,7],
      :branch          => branch_name,
      :commit_count    => commit_count
    }
  end

  def calculate_commit_count
    push_commit_extractor.new_commits.count
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
    meta_body(@spec.head? ? "branch" : "tag")
  end

  def meta_body(type)
    @spec.action_create? ? "Created #{type} #{@spec.ref_name}" : "Deleted #{type} #{@spec.ref_name}"
  end
end
