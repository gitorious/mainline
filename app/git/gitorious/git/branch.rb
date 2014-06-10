# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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

require 'gitorious/git/commit'

module Gitorious
  module Git
    class Branch
      def initialize(rugged_branch, rugged_repository)
        @rugged_branch = rugged_branch
        @rugged_repository = rugged_repository
      end

      def name
        rugged_branch.name
      end

      def commits
        walker = Rugged::Walker.new(rugged_repository)
        walker.sorting(Rugged::SORT_TOPO)
        walker.push(rugged_branch.target_id)
        walker.map { |c| Commit.new(c) }
      end

      def commits_not_merged_upstream(upstream_branch)
        Commits.not_merged_upstream(commits, upstream_branch.commits)
      end

      attr_reader :rugged_branch, :rugged_repository
      private :rugged_branch, :rugged_repository
    end
  end
end

