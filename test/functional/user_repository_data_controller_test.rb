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

class UserRepositoryDataControllerTest < ActionController::TestCase
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
      assert_equal "{}", JSON.parse(response.body)["repository"]
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

    should "indicate that user watches repository" do
      login_as(:johan)
      get :show, :id => @repository.id, :format => "json"

      assert JSON.parse(response.body)["repository"]["watching"]
    end

    should "indicate that user is not watching repository" do
      login_as(:moe)
      get :show, :id => @repository.id, :format => "json"

      assert !JSON.parse(response.body)["repository"]["watching"]
    end

    should "indicate available clone protocols" do
      login_as(:johan)
      get :show, :id => @repository.id, :format => "json"

      protocols = JSON.parse(response.body)["repository"]["cloneProtocols"]
      assert_equal ["git", "http", "ssh"], protocols
    end

    should "indicate available clone protocols for non-owner" do
      login_as(:moe)
      get :show, :id => @repository.id, :format => "json"

      protocols = JSON.parse(response.body)["repository"]["cloneProtocols"]
      assert_equal ["git", "http"], protocols
    end
  end
end
