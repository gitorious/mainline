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

class ProjectViewStateControllerTest < ActionController::TestCase
  def setup
    @project = projects(:johans)
  end

  context "#show" do
    should "respond with 404 if project is not found" do
      get :show, :id => 666, :format => "json"

      assert_response 404
    end

    should "render hash" do
      get :show, :id => @project.to_param, :format => "json"

      assert_response 200
      refute_nil JSON.parse(response.body)["project"]
    end

    should "render hash for admin" do
      login_as(:johan)
      get :show, :id => @project.to_param, :format => "json"

      assert_response 200
      assert_equal "/johans-project/edit", JSON.parse(response.body)["project"]["admin"]["editPath"]
    end
  end
end
