#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class CommitRangePresenter
  include Enumerable

  attr_reader :commits
  private :commits

  attr_reader :left, :right

  def self.build(left, right, repository = nil)
    new(
      CommitPresenter.build(repository, left),
      repository.git.commits_between(left, right).map { |commit|
        CommitPresenter.build(repository, commit)
      }
    )
  end

  def initialize(left, commits)
    @left    = left
    @commits = commits
  end

  def each(&block)
    commits.each(&block)
  end

  def last
    commits.last
  end
  alias_method :right, :last
end
