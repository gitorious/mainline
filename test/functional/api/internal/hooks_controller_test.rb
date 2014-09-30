# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

class Api::Internal::HooksControllerTest < ActionController::TestCase

  context "GET #pre_receive" do
    setup do
      @user = mock("user")
      @repository = mock("repository")
      User.expects(:find_by_login).with("bar").returns(@user)
      Repository.expects(:find).with("123").returns(@repository)
    end

    should "respond with 200 when user is allowed to update ref" do
      RefPolicy.expects(:authorize_action!).with(
        @user,
        @repository,
        "refs/heads/master",
        "deadbeef",
        "baadf00d",
        "ba3e"
      )

      get :pre_receive,
        username:   "bar",
        repository_id: 123,
        refname:    "refs/heads/master",
        oldsha:     "deadbeef",
        newsha:     "baadf00d",
        mergebase: "ba3e"

      assert_response :success
    end

    should "respond with 403 when user is not allowed to update ref" do
      RefPolicy.expects(:authorize_action!).with(
        @user,
        @repository,
        "refs/heads/master",
        "deadbeef",
        "baadf00d",
        "ba3e"
      ).raises(RefPolicy::Error)

      get :pre_receive,
        username:   "bar",
        repository_id: 123,
        refname:    "refs/heads/master",
        oldsha:     "deadbeef",
        newsha:     "baadf00d",
        mergebase: "ba3e"

      assert_response :forbidden
    end
  end

  context "POST #post_receive" do
    should "enqueue GitoriousPush message" do
      now = Time.now
      @controller.stubs(:clock).returns(stub('clock', now: now))

      @controller.expects(:publish).with('/queue/GitoriousPush', {
        repository_id: "123",
        message:  "deadbeef baadf00d refs/heads/master",
        username: "bar",
        pushed_at: now.iso8601,
      })

      post :post_receive,
        username:  "bar",
        repository_id: 123,
        refname:   "refs/heads/master",
        oldsha:    "deadbeef",
        newsha:    "baadf00d"

      assert_response :success
    end
  end

end
