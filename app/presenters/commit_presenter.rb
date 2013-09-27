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
  attr_reader :repository, :id

  def initialize(repository, oid)
    @git = repository.git
    @repository = RepositoryPresenter.new(repository)
    @id = oid
  end

  def commit; @commit ||= @git.commit(id); end
  def short_oid; id[0,7]; end
  def project; repository.project; end
  def diffs; commit.parents.empty? ? [] : commit.diffs; end
  def raw_diffs; diffs.map { |d| d.diff }.join("\n"); end
  def exists?; !commit.nil?; end
  def to_patch; commit.to_patch; end
  def merge?; commit.merge?; end
  def stats; commit.stats; end
  def parents; commit.parents; end
  def message; commit.message; end
  def committer; commit.committer; end
  def author; commit.author; end
  def committed_date; commit.committed_date; end
  def authored_date; commit.authored_date; end

  def committer_user
    User.find_by_email_with_aliases(committer.email)
  end

  def author_user
    User.find_by_email_with_aliases(author.email)
  end
end
