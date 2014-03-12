# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2010 Marius Mathiesen <marius@shortcut.no>
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

class MergeRequestVersionProcessorTest < ActiveSupport::TestCase
  def setup
    @processor = MergeRequestVersionProcessor.new
    @version = merge_request_versions(:first_version_of_johans_to_mikes)
    @merge_request = @version.merge_request
    @tracking_repository = @merge_request.tracking_repository
    @source_repository = @merge_request.source_repository
    @message = @version.branch_deletion_message
  end

  def teardown
    @processor = nil
  end

  context "Deletion of merge request tracking branches" do
    should "push an empty tag to the target repository" do
      repo = mock
      repo.expects(:push).with(
        { :timeout => false },
        @tracking_repository.full_repository_path,
        ":#{@merge_request.ref_name(@version.version)}")
      @source_repository.expects(:git).returns(mock(:git => repo))
      @processor.stubs(:source_repository).returns(@source_repository)

      @processor.consume(@message.to_json)
    end
  end

  context "Missing git repository" do
    setup do
      @processor.consume(@message.to_json)
    end

    should "log an appropriate message when source repository is missing" do
      @processor.logger.expects(:error)
      @processor.delete_branch
    end
  end

  context "Internals" do
    setup do
      @processor.consume(@message.to_json)
    end

    should "extract the correct source repository path" do
      assert_equal(@source_repository.full_repository_path,
        @processor.source_repository_path)
    end

    should "extract the correct tracking repository path" do
      assert_equal(@tracking_repository.full_repository_path,
        @processor.tracking_repository_path)
    end

    should "extract the branch name" do
      assert_equal(@merge_request.ref_name(@version.version),
        @processor.target_branch_name)
    end

    should "find the source repository" do
      assert_equal @source_repository, @processor.source_repository
    end
  end
end
