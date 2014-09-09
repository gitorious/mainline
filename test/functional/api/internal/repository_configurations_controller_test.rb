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

class Api::Internal::RepositoryConfigurationsControllerTest < ActionController::TestCase

  context "GET #show" do
    setup do
      @user = mock("user")
      @repository = repositories(:johans)
      User.expects(:find_by_login).with("bar").returns(@user)
      Repository.expects(:find_by_path).with("repo/path").returns(@repository)
    end

    should "respond with repo configuration when user can read repo" do
      @controller.expects(:can_read?).with(@user, @repository).returns(true)

      get :show, username: "bar", repo_path: "repo/path", format: :json

      assert_response :success
      assert_equal({
        "real_path"      => "c2a/943/aad718337973577b555383db50ae03e01c.git",
        "ssh_clone_url"  => "git@gitorious.test:johans-project/johansprojectrepos.git",
        "http_clone_url" => "http://gitorious.test/johans-project/johansprojectrepos.git",
        "git_clone_url"  => "git://gitorious.test/johans-project/johansprojectrepos.git",
      }, JSON.parse(response.body))
    end

    should "respond with 403 when user can't read repo" do
      @controller.expects(:can_read?).with(@user, @repository).returns(false)

      get :show, username: "bar", repo_path: "repo/path", format: :json

      assert_response :unauthorized
    end
  end

end
