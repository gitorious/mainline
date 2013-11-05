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
require "fast_test_helper"
require "sample_repo_helpers"
require "gitorious/ref_name_resolver"

module Gitorious
  class RefNameResolverTest < MiniTest::Spec
    include SampleRepoHelpers
    let(:repo) { sample_repo("push_test_repo.git") }

    it "returns ref name for a commit matching the ref sha" do
      assert_equal "master", RefNameResolver.sha_to_ref_name(repo, "ec43317")
    end

    it "returns the commit id otherwise" do
      assert_equal "6ad786", RefNameResolver.sha_to_ref_name(repo, "6ad786")
    end
  end
end
