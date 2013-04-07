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

class MergeRequestProcessorTest < ActiveSupport::TestCase
  def setup
    @processor = MergeRequestProcessor.new
    @merge_request = merge_requests(:moes_to_johans_open)
    @target_repo = @merge_request.target_repository
    @merge_request.stubs(:target_repository).returns(@target_repo)
    MergeRequest.expects(:find).with(@merge_request.id).returns(@merge_request)
    @tracking_repo = mock("Tracking repository")
    @tracking_repo.stubs(:real_gitdir).returns("ff0/bbc/234")
    @target_repo.stubs(:create_tracking_repository).returns(@tracking_repo)
  end

  should "send a repo creation message when the target repo does not have a MR repo" do
    message = { "merge_request_id" => @merge_request.id }.to_json
    @target_repo.expects(:has_tracking_repository?).once.returns(false)
    CreateTrackingRepositoryCommand.any_instance.expects(:execute).returns(@tracking_repo)
    @merge_request.expects(:"push_to_tracking_repository!").with(true).once
    MergeRequestProcessor.new.consume(message)
  end

  should "create a new branch from the merge request" do
    message = { "merge_request_id" => @merge_request.id }.to_json
    @target_repo.expects(:has_tracking_repository?).once.returns(true)
    @merge_request.expects(:push_to_tracking_repository!).once
    @processor.consume(message)
  end
end
