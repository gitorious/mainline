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
module Gitorious
  class Commit
    def initialize(grit_commit)
      @grit_commit = grit_commit
    end

    def email
      @grit_commit.committer.email
    end

    def user
      User.find_by_email_with_aliases(email)
    end

    def data
      @grit_commit.id
    end

    def id
      @grit_commit.id
    end

    def created_at
      @grit_commit.committed_date
    end

    def body
      @grit_commit.message
    end

    def actor_display
      @grit_commit.committer.name
    end

    def self.load_commits_between(grit_repo, first_sha, last_sha, event_id)
      Rails.cache.fetch("commits_for_push_event_#{event_id}") do
        grit_repo.commits_between(first_sha, last_sha).map {|c| new(c)}.reverse
      end
    end
  end
end
