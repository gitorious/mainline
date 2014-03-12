# encoding: utf-8
#--
#   Copyright (C) 2011-2013 Gitorious AS
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

class MergeRequestVersionsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context

  context "Viewing diffs" do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
      @merge_request.status = MergeRequest::STATUS_OPEN
      @merge_request.status_tag = "Open"
      @merge_request.save
      @version = @merge_request.create_new_version('ffac0')
      @git = mock

      #(repo, id, parents, tree, author, authored_date, committer, committed_date, message)
      @commit = Grit::Commit.new(mock("repo"), "mycommitid", [], stub_everything("tree"),
                                 stub_everything("author"), Time.now, stub_everything("comitter"), Time.now,
                                 "my commit message".split(" "))

      Repository.any_instance.stubs(:git).returns(@git)
      MergeRequestVersion.stubs(:find_by_version!).returns(@version)
    end

    should "show all the diffs for this version" do
      @version.expects(:diffs).with(nil).returns([])
      @git.expects(:commit).with("286e8afb9576366a2a43b12b94738f07").returns(@commit)

      get :show, params(:version => @version.to_param)

      assert_response :success
    end
  end

  def params(extras)
    { :project_id => @merge_request.project.to_param,
      :repository_id => @merge_request.target_repository.to_param,
      :merge_request_id => @merge_request.to_param }.merge(extras)
  end
end
