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

class ProjectOwnershipsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context

  def setup
    @project = projects(:johans)
    @project.owner = users(:mike)
    @project.save
    @group = users(:mike).groups.first
    login_as :mike
  end

  should "get a list of the users' groups on edit" do
    group = groups(:a_team)
    mike = users(:mike)
    assert !group.member?(mike)
    group.add_member(mike, Role.member)

    get :edit, :id => @project.to_param

    assert_response :success
    refute_match group.name, @response.body, "included group where user is only member"
  end

  should "change the owner" do
    put :update, :id => @project.to_param, :project => {
      :owner_type => "Group",
      :owner_id => @group.id
    }

    assert_redirected_to(project_path(@project))
    assert_equal @group, @project.reload.owner
  end
end
