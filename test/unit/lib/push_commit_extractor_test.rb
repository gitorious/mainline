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
# Commit log
# 7b5fe553c3c37ffc8b4b7f8c27272a28a39b640f (not in any head)
# bb17eec3080ed71fa4ea7aba6b500aac9339e159 (not in any head)
# ec433174463a9d0dd32700ffa5bbb35cfe2a4530 (master)

require "test_helper"
require "push_spec_parser"
require "push_commit_extractor"
class PushCommitExtractorTest < ActiveSupport::TestCase
  context "Extract commits in a push event" do
    setup do
      @repo_path = (Rails.root + "test/fixtures/push_test_repo.git").to_s
      @first_new_commit = "bb17eec3080ed71fa4ea7aba6b500aac9339e159"
      @second_new_commit = "7b5fe553c3c37ffc8b4b7f8c27272a28a39b640f"
    end

    should "find heads excluding current" do
      spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/topic")
      extractor = PushCommitExtractor.new(@repo_path, spec)
      assert_equal ["master"], extractor.existing_ref_names
    end

    should "count new commits in push" do
      spec = PushSpecParser.new(NULL_SHA, @first_new_commit, "refs/heads/topic")
      extractor = PushCommitExtractor.new(@repo_path, spec)
      assert_equal 1, extractor.new_commits.count
    end

    should "extract new commit shas" do
      spec = PushSpecParser.new(NULL_SHA, @second_new_commit, "refs/heads/topic")
      extractor = PushCommitExtractor.new(@repo_path, spec)
      assert_equal [@second_new_commit, @first_new_commit], extractor.new_commits.map(&:oid)
    end

    should "extract newest existing commit" do
      spec = PushSpecParser.new(NULL_SHA, @first_new_commit, "refs/heads/topic")
      extractor = PushCommitExtractor.new(@repo_path, spec)
      assert_equal "ec433174463a9d0dd32700ffa5bbb35cfe2a4530", extractor.newest_known_commit.oid
    end
  end
end
