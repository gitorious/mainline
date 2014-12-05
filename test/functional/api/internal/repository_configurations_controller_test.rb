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
      User.stubs(:find_by_login).with("bar").returns(@user)
      Repository.stubs(:find_by_path).with("repo/path.git").returns(@repository)
    end

    should "respond with repo configuration when user can read repo" do
      RepositoryPolicy.expects(:allowed?).with(@user, @repository, :read).returns(true)

      get :show, username: "bar", repo_path: "repo/path.git", format: :json

      assert_response :success
      assert_equal({
        "id"             => 1,
        "repository_id"  => 1,
        "full_path"      => RepositoryRoot.expand("c2a/943/aad718337973577b555383db50ae03e01c.git").to_s,
        "ssh_clone_url"  => "git@gitorious.test:johans-project/johansprojectrepos.git",
        "http_clone_url" => "http://gitorious.test/johans-project/johansprojectrepos.git",
        "git_clone_url"  => "git://gitorious.test/johans-project/johansprojectrepos.git",
      }, JSON.parse(response.body))
    end

    should "respond with 404 when repo path is invalid" do
      Repository.stubs(:find_by_path).with("repo/path.git").returns(nil)

      get :show, username: "bar", repo_path: "repo/path.git", format: :json

      assert_response :not_found
    end

    should "respond with 403 when user can't read repo" do
      RepositoryPolicy.expects(:allowed?).with(@user, @repository, :read).returns(false)

      get :show, username: "bar", repo_path: "repo/path.git", format: :json

      assert_response :forbidden
    end
  end

end
