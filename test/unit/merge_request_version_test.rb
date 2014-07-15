# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

require "test_helper"
load 'app/models/merge_request_version.rb'

class MergeRequestVersionTest < ActiveSupport::TestCase
  context 'In general' do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
      @first_version = @merge_request.create_new_version('ffcca0')
    end

    should 'ask the target repository for commits' do
      repo = mock("Tracking git repo")
      repo.expects(:commits_between).with(
        @first_version.merge_base_sha,
        @merge_request.ref_name(@first_version.version)
      ).returns([])
      tracking_repo = mock("Tracking repository")
      tracking_repo.stubs(:id).returns(999)
      tracking_repo.stubs(:git).returns(repo)
      @merge_request.stubs(:tracking_repository).returns(tracking_repo)
      @first_version.stubs(:merge_request).returns(@merge_request)
      @first_version.affected_commits
    end

    should 'cache affected_commits' do
      expected_cache_key = "#{@first_version.cache_key}/affected_commits"
      Rails.cache.expects(:fetch).with(expected_cache_key).returns([])
      @first_version.affected_commits
    end

    should "have a unique cache key between versions" do
      second_version = @merge_request.create_new_version('cacaca')
      assert_not_equal @first_version.cache_key, second_version.cache_key
    end
  end

  context 'Diff browsing' do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
      @version = @merge_request.create_new_version('ffcca0')
      @diff_backend = mock
      @version.stubs(:diff_backend).returns(@diff_backend)
    end

    should 'handle a range' do
      @diff_backend.expects(:commit_diff).with("ffc","ccf", true)
      @version.diffs("ffc".."ccf")
    end

    should 'handle a single commit' do
      @diff_backend.expects(:single_commit_diff).with("ffc")
      @version.diffs("ffc")
    end

    should 'handle all commits' do
      @version.stubs(:affected_commits).returns([FakeGritCommit.new('ff'), FakeGritCommit.new('aa')])
      @diff_backend.expects(:commit_diff).with('aa', 'ff', true)
      @version.diffs
    end
  end

  context "Sha summaries" do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
      @merge_request.stubs(:calculate_merge_base).returns("ffca0")
      @version = @merge_request.create_new_version('ffca0')
    end

    should "be the merge base only if no affected commits" do
      @version.stubs(:affected_commits).returns([])
      assert_equal "ffca0", @version.sha_summary
    end

    should "specify the first and last affected commits, in reverse order" do
      affected_commits = [
        stub(
          :id => "82f4a08e2c0867956fdc797692e3d127ba7b8e8c", :id_abbrev => "82f4"),
        stub(
          :id => "1e4e040fa4c164537a90303ae95eae3bd895a95e", :id_abbrev => "1e4e")]
      @version.stubs(:affected_commits).returns(affected_commits)
      assert_equal "1e4e-82f4", @version.sha_summary
      assert_equal "1e4e040fa4c164537a90303ae95eae3bd895a95e-82f4a08e2c0867956fdc797692e3d127ba7b8e8c",
         @version.sha_summary(:long)
    end
  end

  context "The diff backend" do
    include SampleRepoHelpers

    setup {
      @backend = MergeRequestVersion::DiffBackend.new(nil)
    }

    should "have a cache key" do
      assert_equal "merge_request_diff_v1_ff0_cc9", @backend.cache_key("ff0", "cc9")
      assert_equal "merge_request_diff_v1_ff0", @backend.cache_key("ff0")
    end

    should "ask the cache for diffs for a range of commits" do
      Rails.cache.expects(:fetch).with("merge_request_diff_v1_ff9_cc9").returns("some_string")
      assert_equal "some_string", @backend.commit_diff("ff9", "cc9")
    end

    should "ask the cache for diffs for a single commit" do
      Rails.cache.expects(:fetch).with("merge_request_diff_v1_f00").returns("foo_bar")
      assert_equal "foo_bar", @backend.single_commit_diff("f00")
    end

    should "return commits diff" do
      repo = sample_repo('with_binaries')
      backend = MergeRequestVersion::DiffBackend.new(repo)

      diffs = backend.commit_diff("d26a845ccc77c471f0d6acadf8c72669e83a9585",
                                  "771cece5bb44e2918adf6d2eb05d86af0dd50492")
      files = diffs.map { |f| [f.b_path, f.b_blob.binary?] }

      assert_equal [["README", false], ["favicon.ico", true]], files
    end
  end

  context 'Commenting' do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
      @first_version = @merge_request.create_new_version('ffcca0')
      @comment = @first_version.comments.create(:path => "README", :lines => "1-1:1-32+33",
        :sha1 => "ffac-aafc", :user => @merge_request.user,  :body => "Needs more cowbell",
        :project => @merge_request.target_repository.project)
    end

    should 'fetch all comments with the specified sha' do
      assert_equal([@comment], @first_version.comments_for_sha("ffac-aafc"))
    end

    should 'combine version and MR comments into a single array' do
      @mr_comment = @merge_request.comments.create!(
        :body => "Beware high gamma levels",
        :user => users(:moe),
        :project => @merge_request.target_repository.project
        )
      assert_equal([@comment, @mr_comment], @first_version.comments_for_sha("ffac-aafc",
          :include_merge_request_comments => true))
    end
  end

  context "Deletion of branches" do
    setup {
      @version = merge_request_versions(:first_version_of_johans_to_mikes)
      @merge_request = @version.merge_request
    }

    should "send a deletion notification when destroyed" do
      @version.expects(:schedule_branch_deletion)
      @version.destroy
    end

    should "build a message for deleting the tracking branch" do
      result = {
        :source_repository_path => @merge_request.source_repository.full_repository_path,
        :tracking_repository_path => @merge_request.tracking_repository.full_repository_path,
        :target_branch_name => @merge_request.ref_name(@version.version),
        :source_repository_id => @merge_request.source_repository.id
      }
      assert_equal result, @version.branch_deletion_message
    end

    should "send the deletion message to the message queue" do
      @version.schedule_branch_deletion

      assert_messages_published "/queue/GitoriousMergeRequestVersionDeletion", 1
    end
  end

  context "On creation" do
    setup do
      merge_request = merge_requests(:moes_to_johans)
      version = merge_request.versions.build :version => 22, :merge_base_sha => OTHER_SHA
      version.save
      @comment = version.comments.first
    end

    should "create a comment when created" do
      assert_not_nil @comment
      refute @comment.editable?
      assert @comment.body =~ /Pushed new version [\d]+/
    end
  end
end
