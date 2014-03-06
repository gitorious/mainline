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

require 'test_helper'

class MergeRequestCommitsTest < ActiveSupport::TestCase
  include SampleRepoHelpers

  test "returns commits that are in source repository but not in target" do
    source_path = sample_repo_path("cloned_repo")
    source_repo = Gitorious::Git::Repository.from_path(source_path)
    source = source_repo.branch("master")
    target_path = sample_repo_path("original_repo")
    target_repo = Gitorious::Git::Repository.from_path(target_path)
    target = target_repo.branch("master")

    commits = source.commits_not_merged_upstream(target)

    messages = commits.map(&:short_message)
    assert_equal ["Changed readme in clone", "changed on clone"], messages
  end
end
