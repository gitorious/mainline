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
require 'sample_repo_helpers'
require 'gitorious/git/branch'

require 'rugged'

module Gitorious
  module Git
    class BranchTest < MiniTest::Spec
      include SampleRepoHelpers

      describe "#name" do
        it "returns the branch name" do
          repo = sample_rugged_repo
          rugged_branch = repo.branches['master']
          branch = Branch.new(rugged_branch, repo)

          branch.name.must_equal 'master'
        end
      end

      describe "#commits" do
        it "returns all the commits reachable from branch head" do
          repo = sample_rugged_repo('original_repo')
          rugged_branch = repo.branches['master']
          branch = Branch.new(rugged_branch, repo)

          commits = branch.commits

          commits.map(&:id).must_equal %w[
            bc4feafacd8aaec5ba1c4e05943e45741f3d3c06
            7a81cc287f6b5d174c2ac53fc656869fe3c8b454
            fda0e8cd42b96fb9e3b92f7cc70e2a0b1524336e
            b057108f8d95395a89128198c2b2d3f725900248
            f83a7006c53a87f323d5db437d021387a5d3bf07
            08d338a09de4b21082dd986bec1a773ea24871d6
          ]
        end
      end
    end
  end
end
