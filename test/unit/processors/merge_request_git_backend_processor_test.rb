# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class MergeRequestGitBackendProcessorTest < ActiveSupport::TestCase
  def setup
    @processor = MergeRequestGitBackendProcessor.new
    @merge_request = merge_requests(:moes_to_johans)
    @repository = @merge_request.target_repository
  end

  def teardown
    @processor = nil
  end

  context "Deleting the merge request and its tracking branch" do
    setup do
      @source_git_repo = mock
      @source_git = mock
      @source_git_repo.stubs(:git).returns(@source_git)
      @merge_request.source_repository.stubs(:git).returns(@source_git_repo)
      @msg = {
        :action => "delete",
        :target_name => @merge_request.target_repository.url_path,
        :ref_name => @merge_request.ref_name,
        :source_repository_id => @merge_request.source_repository.id,
        :target_repository_id => @merge_request.target_repository.id,
      }
    end

    should "push to delete the tracking branch" do
      @processor.stubs(:source_repository).returns(@merge_request.source_repository)
      @source_git.expects(:push).with({:timeout => false},
        @merge_request.target_repository.full_repository_path,
        ":#{@merge_request.ref_name}")
      @processor.consume(@msg.to_json)
    end

    should "handle non-existing target gits" do
      assert_nothing_raised do
        @processor.consume(@msg.to_json)
      end
    end
  end

  context "Parsing the action" do
    should "understand the delete command" do
      msg = {:merge_request_id => @merge_request.to_param, :action => "delete"}
      @processor.expects(:do_delete).once
      @processor.consume(msg.to_json)

      assert_equal "delete", @processor.action
    end
  end
end
