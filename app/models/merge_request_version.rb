# encoding: utf-8
#--
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
  belongs_to :merge_request
  has_many :comments, :as => :target

  def affected_commits
    Rails.cache.fetch(cache_key, :expires_in => 60.minutes) do
      @affected_commits ||= merge_request.tracking_repository.git.commits_between(
        merge_base_sha, merge_request.merge_branch_name(version)).reverse
    end
  end

  def cache_key
    "commits_in_merge_request_version_#{id}"
  end

  def diffs(sha_or_range=nil)
    case sha_or_range
    when Range
      diff_backend.commit_diff(sha_or_range.begin, sha_or_range.end, true)
    when String
      diff_backend.single_commit_diff(sha_or_range)
    else
      diff_backend.commit_diff(merge_base_sha, merge_request.ending_commit)
    end    
  end

  def comments_for_path(path)
    comments.select{|c|c.path == path}
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
      ["merge_request_diff", first, last].compact.join("_")
    end
    
    def commit_diff(first, last, diff_with_previous=false)
      Rails.cache.fetch(cache_key(first,last), :expires_in => 60.minutes) do
        first_commit_sha = if diff_with_previous
                             parent_commit_sha(first)
                           else
                             first
                           end
        diff_string = @repository.git.ruby_git.diff(first_commit_sha ,last)
        Grit::Diff.list_from_string(@repository, diff_string)
      end
    end

    def single_commit_diff(sha)
      Rails.cache.fetch(cache_key(sha), :expires_in => 60.minutes) do
        @repository.commit(sha).diffs
      end
    end
  end
end
