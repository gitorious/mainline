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

class UserFeedsControllerTest < ActionController::TestCase
  should "render atom feed" do
    user = users(:johan)
    project = user.projects.first
    create_event(user, project, project.repositories.first)
    create_event(user, project, project.repositories.first)

    get :show, :id => user.login, :format => "atom"

    assert_response :success
    assert_match "johan's activity", response.body
    assert_equal 2, Hash.from_xml(response.body)["feed"]["entry"].length
  end

  context "With private repositories" do
    setup do
      @user = users(:johan)
      @project = @user.projects.first
      enable_private_repositories
    end

    should "exclude unauthorized events from atom feed" do
      create_event(@user, projects(:moes), @project.repositories.first)
      create_event(@user, @project, @project.repositories.first)
      create_event(@user, projects(:moes), projects(:moes).repositories.first)

      get :show, :id => @user.to_param, :format => "atom"

      # Hash.from_xml does not make an array of elements when there's only one
      assert Hash.from_xml(response.body)["feed"]["entry"].is_a?(Hash)
    end

    should "include authorized events in atom feed" do
      create_event(@user, projects(:moes), @project.repositories.first)
      create_event(@user, @project, @project.repositories.first)
      create_event(@user, projects(:moes), projects(:moes).repositories.first)

      login_as :johan
      get :show, :id => @user.to_param, :format => "atom"

      assert_equal 3, Hash.from_xml(response.body)["feed"]["entry"].length
    end
  end

  private
  def create_event(user, project, target)
    e = Event.new({ :target => target,
                    :data => "master",
                    :action => Action::CREATE_BRANCH })
    e.user = user
    e.project = project
    e.save!
  end
end
