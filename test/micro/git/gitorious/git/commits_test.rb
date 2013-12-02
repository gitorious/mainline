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

require 'fast_test_helper'
require 'gitorious/git/commits'

module Gitorious
  module Git
    class CommitsTest < MiniTest::Spec
      def commits(changesets)
        changesets.map { |commit| stub(id: commit[:id], changeset: commit[:changeset]) }
      end

      describe ".not_merged_upstream" do
        it "returns all the commits which don't have a corresponding changeset upstream" do
          source_commits = commits([
            { id: 1, changeset: 'foo' },
            { id: 2, changeset: 'bar' },
            { id: 3, changeset: 'baz' },
            { id: 4, changeset: 'bam' }
          ])
          upstream_commits = commits([
            { id: 5, changeset: '123' },
            { id: 1, changeset: 'foo' },
            { id: 6, changeset: '256' },
            { id: 7, changeset: 'baz' }
          ])

          commits = Commits.not_merged_upstream(source_commits, upstream_commits)

          commits.map(&:changeset).must_equal %w[bar bam]
        end
      end
    end
  end
end

