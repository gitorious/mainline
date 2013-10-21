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

class MergeRequestStatusTest < ActiveSupport::TestCase
  should belong_to(:project)
  should validate_presence_of(:project)
  should validate_presence_of(:state)
  should validate_presence_of(:name)

  context "State" do
    setup do
      @project = Project.first
      @status = MergeRequestStatus.new({
          :project => @project,
          :name => "foo",
          :state => MergeRequest::STATUS_OPEN
        })
    end

    should "be open? when the state is open" do
      @status.state = MergeRequest::STATUS_OPEN
      assert @status.open?
      assert !@status.closed?
    end

    should "be closed? when the state is closed" do
      @status.state = MergeRequest::STATUS_CLOSED
      assert !@status.open?
      assert @status.closed?
    end

    should "create default statuses for a project" do
      @project.merge_request_statuses.destroy_all
      MergeRequestStatus.create_defaults_for_project(@project)
      assert_equal 2, @project.reload.merge_request_statuses.size

      assert @project.merge_request_statuses.first.open?
      assert @project.merge_request_statuses.first.default?

      assert @project.merge_request_statuses.last.closed?
      assert !@project.merge_request_statuses.last.default?
    end

    context "updating affected merge requests" do
      setup do
        @merge_requests = @project.repositories.mainlines.map(&:merge_requests).flatten
        assert_equal 3, @merge_requests.size
        assert @status.save
        @merge_requests.last.update_attribute(:status_tag, @status.name)
      end

      should "only change the status of the merge requests with the same status_tag" do
        assert_equal MergeRequest::STATUS_PENDING_ACCEPTANCE_OF_TERMS,
          @merge_requests[0].status
        assert_equal MergeRequest::STATUS_OPEN, @merge_requests[1].status
        assert_equal MergeRequest::STATUS_OPEN, @merge_requests[2].status

        @status.state = MergeRequest::STATUS_CLOSED
        @status.save!

        assert_equal MergeRequest::STATUS_PENDING_ACCEPTANCE_OF_TERMS,
          @merge_requests[0].reload.status
        assert_equal MergeRequest::STATUS_OPEN, @merge_requests[1].reload.status
        assert_equal MergeRequest::STATUS_CLOSED, @merge_requests[2].reload.status
      end

      should "only change the status_tag of the merge requests, if the name is changed" do
        assert_equal MergeRequest::STATUS_OPEN, @merge_requests[1].status
        assert_equal MergeRequest::STATUS_OPEN, @merge_requests[2].status
        @merge_requests[2].update_attribute(:status_tag, @status.name)

        assert_equal "open", @merge_requests[1].status_tag.to_s
        assert_equal "foo", @merge_requests[2].status_tag.to_s

        @status.name = "SomethingElse"
        @status.save!

        assert_equal MergeRequest::STATUS_OPEN, @merge_requests[1].reload.status
        assert_equal MergeRequest::STATUS_OPEN, @merge_requests[2].reload.status
        assert_equal "open", @merge_requests[1].reload.status_tag.to_s
        assert_equal "SomethingElse", @merge_requests[2].reload.status_tag.to_s

      end

    end
  end
end
