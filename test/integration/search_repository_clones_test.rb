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

class RepositoryCloneSearchTest < ActionDispatch::IntegrationTest
  def login(user)
    open_session do |session|
      session.host = Gitorious.host
      session.post("/sessions", :email => user.email, :password => "test")
      yield session
    end
  end

  should "search repository clones as JSON" do
    get "/johans-project/johansprojectrepos/search_clones.json?filter=projectrepos"

    assert_response :success
    repositories = JSON.load(response.body)
    assert_equal 1, repositories.length
    assert_equal repositories(:johans2).name, repositories.first["name"]
  end

  context "with private repositories" do
    setup do
      enable_private_repositories
      repositories(:johans2).make_private
    end

    should "not render private repository clones to unauthorized users" do
      login(users(:zmalltalker)) do |session|
        session.get "/johans-project/johansprojectrepos/search_clones.json?filter=projectrepos"
        session.assert_response :success
        assert_equal 0, JSON.load(session.response.body).length
      end
    end

    should "render private repository clones to authorized users" do
      login(users(:johan)) do |session|
        session.get "/johans-project/johansprojectrepos/search_clones.json?filter=projectrepos"
        session.assert_response :success
        assert_equal 1, JSON.load(session.response.body).length
      end
    end
  end
end
