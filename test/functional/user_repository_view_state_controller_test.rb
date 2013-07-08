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
require "test_helper"

class UserRepositoryViewStateControllerTest < ActionController::TestCase
  def setup
    @repository = repositories(:johans)
  end

  context "#show" do
    should "respond with empty json object if user is not logged in" do
      get :show, :id => @repository.id, :format => "json"

      assert_response 200
      assert_equal "{}", response.body
    end

    should "respond with json payload for logged in user" do
      login_as(:moe)
      get :show, :id => @repository.id, :format => "json"

      assert_response 200
      data = JSON.parse(response.body)
      assert_equal "moe", data["user"]["login"]
    end

    should "have empty repository if repository is not found" do
      login_as(:moe)
      get :show, :id => 666, :format => "json"

      assert_response 200
      assert_nil JSON.parse(response.body)["repository"]
    end

    # TODO: Convert the following tests to micro tests

    should "incude unread message count" do
      login_as(:moe)
      get :show, :id => @repository.id, :format => "json"

      assert_equal 1, JSON.parse(response.body)["user"]["unreadMessageCount"]
    end

    should "incude user paths" do
      login_as(:moe)
      get :show, :id => @repository.id, :format => "json"

      assert_equal "/", JSON.parse(response.body)["user"]["dashboardPath"]
      assert_equal "/~moe/edit", JSON.parse(response.body)["user"]["editPath"]
      assert_equal "/~moe", JSON.parse(response.body)["user"]["profilePath"]
      assert_equal "/messages", JSON.parse(response.body)["user"]["messagesPath"]
      assert_equal "/logout", JSON.parse(response.body)["user"]["logoutPath"]
      assert_equal "http://www.gravatar.com/avatar/a59f9d19e6a527f11b016650dde6f4c9&amp;default=http://gitorious.test/images/default_face.gif", JSON.parse(response.body)["user"]["avatarPath"]
    end

    should "incude avatar if user has one" do
      login_as(:johan)
      user = users(:johan)
      avatar = Object.new
      def avatar.url(type); "/avatar"; end
      User.any_instance.stubs(:avatar?).returns(true)
      User.any_instance.stubs(:avatar).returns(avatar)

      get :show, :id => @repository.id, :format => "json"

      assert_equal "/avatar", JSON.parse(response.body)["user"]["avatarPath"]
    end

    should "indicate that user is not an administrator for the repository" do
      login_as(:moe)
      get :show, :id => repositories(:johans_wiki).id, :format => "json"

      assert !JSON.parse(response.body)["repository"]["administrator"]
    end

    should "indicate that user is an administrator for the repository" do
      login_as(:johan)
      get :show, :id => @repository.id, :format => "json"

      assert JSON.parse(response.body)["repository"]["administrator"]
    end

    should "include repository admin URLs" do
      login_as(:johan)
      get :show, :id => @repository.id, :format => "json"

      paths = JSON.parse(response.body)["repository"]["admin"]
      prefix = "johans-project/johansprojectrepos"
      assert_equal "/#{prefix}/edit", paths["editPath"]
      assert_equal "/#{prefix}/confirm_delete", paths["destroyPath"]
      assert_equal "/#{prefix}/ownership/edit", paths["ownershipPath"]
      assert_equal "/#{prefix}/committerships", paths["committershipsPath"]
    end

    should "indicate that user watches repository" do
      login_as(:johan)
      get :show, :id => @repository.id, :format => "json"

      watch = {
        "watching" => true,
        "watchPath" => "/favorites?watchable_id=1&watchable_type=Repository",
        "unwatchPath" => "/favorites/#{users(:johan).favorites.first.id}"
      }
      assert_equal watch, JSON.parse(response.body)["repository"]["watch"]
    end

    should "indicate that user can watch repository" do
      login_as(:moe)
      get :show, :id => @repository.id, :format => "json"

      watch = { "watching" => false, "watchPath" => "/favorites?watchable_id=1&watchable_type=Repository" }
      assert_equal watch, JSON.parse(response.body)["repository"]["watch"]
    end

    should "indicate available clone protocols" do
      login_as(:johan)
      get :show, :id => @repository.id, :format => "json"

      protocols = JSON.parse(response.body)["repository"]["cloneProtocols"]
      assert_equal ["git", "http", "ssh"], protocols["protocols"]
      assert_equal "ssh", protocols["default"]
    end

    should "include clone URL" do
      login_as(:johan)
      get :show, :id => @repository.id, :format => "json"

      repository = JSON.parse(response.body)["repository"]
      assert_equal "/johans-project/johansprojectrepos/clone", repository["clonePath"]
    end

    should "not include clone URL for own repo clown" do
      repo = repositories(:johans2)
      repo.owner = users(:johan)
      repo.save

      login_as(:johan)
      get :show, :id => repositories(:johans2).id, :format => "json"

      repository = JSON.parse(response.body)["repository"]
      assert_nil repository["clonePath"]
    end

    should "include request merge path" do
      repository = repositories(:johans2)
      repository.owner = users(:johan)
      repository.save
      login_as(:johan)
      get :show, :id => repositories(:johans2).id, :format => "json"

      repository = JSON.parse(response.body)["repository"]
      assert_equal "/johans-project/johansprojectrepos/merge_requests/new", repository["requestMergePath"]
    end

    should "not include request merge path for non-clone" do
      login_as(:johan)
      get :show, :id => @repository.id, :format => "json"

      repository = JSON.parse(response.body)["repository"]
      assert_nil repository["requestMergePath"]
    end

    should "not include request merge path for repo not admined by user" do
      login_as(:moe)
      get :show, :id => repositories(:johans2).id, :format => "json"

      repository = JSON.parse(response.body)["repository"]
      assert_nil repository["requestMergePath"]
    end

    should "indicate available clone protocols for non-owner" do
      login_as(:moe)
      get :show, :id => @repository.id, :format => "json"

      protocols = JSON.parse(response.body)["repository"]["cloneProtocols"]
      assert_equal ["git", "http"], protocols["protocols"]
      assert_equal "git", protocols["default"]
    end
  end
end
