# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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

class MergeRequestVersion < ActiveRecord::Base
  include Gitorious::Messaging::Publisher

  belongs_to :merge_request
  has_many :comments, :as => :target, :include => :user
  before_destroy :schedule_branch_deletion
  after_create :add_creation_comment

  def project
    merge_request.project
  end

  def affected_commits
    Rails.cache.fetch(cache_key + '/affected_commits') do
      @affected_commits ||= merge_request.tracking_repository.git.commits_between(
        merge_base_sha, merge_request.ref_name(version)).reverse
    end
  end

  def diffs(sha_or_range=nil)
    case sha_or_range
    when Range
      diff_backend.commit_diff(sha_or_range.begin, sha_or_range.end, true)
    when String
      diff_backend.single_commit_diff(sha_or_range)
    else
      diff_backend.commit_diff(affected_commits.last.id, affected_commits.first.id, true)
    end
  end

  def comments_for_sha(sha, options={})
    result = comments.select{|c|c.sha1 == sha_range_string(sha)}
    if options[:include_merge_request_comments]
      result.concat(merge_request.comments)
    end
    result
  end

  def short_merge_base
    merge_base_sha[0..6]
  end

  def sha_summary(format = :short)
    if affected_commits.blank?
      format == :short ? short_merge_base : merge_base_sha
    else
      meth = format == :short ? :id_abbrev : :id
      [affected_commits.last, affected_commits.first].collect(&meth).join("-")
    end
  end

  def to_param; version; end

  def diff_backend
    @diff_backend ||= DiffBackend.new(merge_request.target_repository.git)
  end

  class DiffBackend
    def initialize(repository)
      @repository = repository
    end

    # Returns the sha of +sha+'s parent. If none, return +sha+
    def parent_commit_sha(sha)
      first_parent = commit = Grit::Commit.find_all(@repository, sha,
        {:max_count => 1}).first.parents.first
      if first_parent.nil?
        sha
      else
        first_parent.id
      end
    end

    def cache_key(first, last=nil)
      ["merge_request_diff_v1", first, last].compact.join("_")
    end

    def commit_diff(first, last, diff_with_previous=false)
      Rails.cache.fetch(cache_key(first,last)) do
        first_commit_sha = if diff_with_previous
                             parent_commit_sha(first)
                           else
                             first
                           end
        Grit::Commit.diff(@repository, first_commit_sha, last)
      end
    end

    def single_commit_diff(sha)
      Rails.cache.fetch(cache_key(sha)) do
        @repository.commit(sha).diffs
      end
    end
  end

  # The unserialized message that is sent to the message queue
  # for deleting the tracking branch
  def branch_deletion_message
    {
      :source_repository_path => merge_request.source_repository.full_repository_path,
      :tracking_repository_path => merge_request.tracking_repository.full_repository_path,
      :target_branch_name => merge_request.ref_name(version),
      :source_repository_id => merge_request.source_repository.id
    }
  end

  def schedule_branch_deletion
    message = branch_deletion_message
    publish("/queue/GitoriousMergeRequestVersionDeletion", message)
  end

  private
  # Returns a string representation of a sha range
  def sha_range_string(string_or_range)
    if Range === string_or_range
      string_or_range = [string_or_range.begin, string_or_range.end].join("-")
    end
    string_or_range
  end

  def add_creation_comment
    comment = comments.build(:user => merge_request.user,
      :body => "Pushed new version #{version}",
      :editable => false,
      :project => merge_request.project)
    comment.save!
  end
end
