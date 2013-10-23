# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
require "repository_presenter"

class CommitPresenter
  attr_reader :repository, :commit, :id

  # FIXME: this is a trick to maintain backward compatibility
  def self.new(repository, commit)
    super(
      repository.is_a?(RepositoryPresenter) ? repository : RepositoryPresenter.new(repository),
      commit.is_a?(String) ? repository.git.commit(commit) : commit
    )
  end

  def initialize(repository, commit)
    @repository = repository
    @commit     = commit
  end

  def summary
    commit.message.split("\n").first
  end

  def actor_display
    commit.committer.name
  end

  def short_oid
    id[0, 7]
  end

  def project
    repository.project
  end

  def diffs
    parents.empty? ? [] : commit.diffs
  end

  def raw_diffs
    diffs.map { |d| d.diff }.join("\n")
  end

  def exists?
    !commit.nil?
  end

  def id
    commit.id
  end

  def short_message
    commit.short_message
  end

  def to_patch
    commit.to_patch
  end

  def merge?
    commit.merge?
  end

  def stats
    commit.stats
  end

  def parents
    commit.parents
  end

  def message
    commit.message
  end

  def committer
    commit.committer
  end

  def author
    commit.author
  end

  def committed_date
    commit.committed_date
  end

  def authored_date
    commit.authored_date
  end

  def committer_user
    User.find_by_email_with_aliases(committer.email)
  end

  def author_user
    User.find_by_email_with_aliases(author.email)
  end
end
