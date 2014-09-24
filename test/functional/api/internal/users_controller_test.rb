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

class Api::Internal::UsersControllerTest < ActionController::TestCase

  context "GET #authenticate" do
    should "respond with authenticated user's information for valid credentials" do
      get :authenticate, username: "johan", password: "test", format: :json

      assert_response :success
      assert_equal({ "username" => "johan" }, JSON.parse(response.body))
    end

    should "respond with 401 when not authenticated" do
      get :authenticate, username: "johan", password: "xxx", format: :json

      assert_response :unauthorized
    end
  end

end
