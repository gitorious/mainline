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

class ProjectMergeRequestsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context

  context "#index (GET)" do
    should "not require login" do
      session[:user_id] = nil
      get :index, :project_id => projects(:johans).slug
      assert_response :success
    end

    should "get all the merge requests in the project" do
      %w(html xml).each do |format|
        project = projects(:johans)

        get :index, :project_id => project.slug, :format => format

        assert_match "plz merge my clone", @response.body
      end
    end
  end
end
