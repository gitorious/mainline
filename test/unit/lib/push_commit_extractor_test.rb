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
# 7a9e44673884f28a309bf6f904431d2b6b4fc09f (annotated tag v0.1.0 => ec43317)
# ec433174463a9d0dd32700ffa5bbb35cfe2a4530 (master)
require "test_helper"
require "push_spec_parser"
require "push_commit_extractor"

class PushCommitExtractorTest < ActiveSupport::TestCase
  context "Extract commits" do
    setup do
      @repo_path = push_test_repo_path
      @first_new_commit = "bb17eec3080ed71fa4ea7aba6b500aac9339e159"
      @second_new_commit = "7b5fe553c3c37ffc8b4b7f8c27272a28a39b640f"
      @master_sha = "ec433174463a9d0dd32700ffa5bbb35cfe2a4530"
    end

    context "in a new branch" do
      should "find heads excluding current" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/topic")
        extractor = PushCommitExtractor.new(@repo_path, spec)
        assert_equal Set.new(["master", "v0.1.0"]), Set.new(extractor.existing_ref_names)
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

      should "handle new branches without new commits" do
        spec = PushSpecParser.new(NULL_SHA, @master_sha, "refs/heads/topic")
        extractor = PushCommitExtractor.new(@repo_path, spec)
        assert_equal 0, extractor.new_commits.count
      end
    end

    context "in an existing branch" do
      should "count new commits" do
        spec = PushSpecParser.new(@master_sha, @first_new_commit, "refs/heads/master")
        extractor = PushCommitExtractor.new(@repo_path, spec)
        assert_equal 1, extractor.new_commits.count
      end
    end

    context "in edge cases" do
      should "behave when creating a new branch from first commit history" do
        first_commit_in_repo = "6ad786d42437fd108ae2290aff67a7d0bb67a9dc"
        spec = PushSpecParser.new(NULL_SHA, first_commit_in_repo, "refs/heads/topic")
        extractor = PushCommitExtractor.new(@repo_path, spec)
        assert_equal first_commit_in_repo, extractor.newest_known_commit.oid
      end
    end

  end
end
