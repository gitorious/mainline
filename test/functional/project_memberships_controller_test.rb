# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class ProjectMembershipsControllerTest < ActionController::TestCase
  def setup
    setup_ssl_from_config
    @project = projects(:johans)
    @user = users(:johan)
  end

  context "With private repos" do
    setup do
      enable_private_repositories
    end

    context "index" do
      should "reject unauthorized user from listing memberships" do
        login_as :mike
        get :index, :project_id => @project.to_param
        assert_response 403
      end

      should "allow owner to manage access" do
        login_as :johan
        get :index, :project_id => @project.to_param
        assert_response 200
      end

      should "state that project is public" do
        login_as :moe
        get :index, :project_id => projects(:moes).to_param

        assert_response 200
        assert_match /This project is public/, @response.body
        assert_match /Make private/, @response.body
      end
    end

    context "create" do
      should "reject unauthorized user" do
        login_as :mike
        login = @user.login
        post :create, :project_id => @project.to_param, :user => { :login => login }
        assert_response 403
      end

      should "add user as a member" do
        login_as :johan

        assert_difference("@project.reload.content_memberships.count") do
          post :create, :project_id => @project.to_param, :user => { :login => users(:moe).login }
        end

        assert_equal @user, @project.content_memberships.first.member
      end

      should "add group as a member" do
        team = groups(:a_team)
        login_as :johan

        assert_difference("@project.reload.content_memberships.count") do
          post :create, :project_id => @project.to_param, :group => { :name => team.name }, :user => { :login => ""}
        end

        assert can_read?(team, @project)
      end

      should "redirect back to index" do
        login = @user.login
        login_as :johan

        post :create, :project_id => @project.to_param, :user => { :login => login }
        assert_response :redirect
        assert_redirected_to :action => "index"
      end

      should "render index if user can not be found" do
        login_as :johan
        post :create, :project_id => @project.to_param, :user => { :login => "login" }

        assert_response 200
        assert_template "index"
        assert_match /No such user 'login'/, flash[:error]
      end

      should "render index if group can not be found" do
        login_as :johan
        post :create, :project_id => @project.to_param, :group => { :name => "login" }

        assert_response 200
        assert_template "index"
        assert_match /No such group 'login'/, flash[:error]
      end
    end

    context "destroy" do
      setup do
        @membership = @project.content_memberships.first
      end

      should "reject unauthorized user" do
        login_as :moe
        delete :destroy, :project_id => @project.to_param, :id => @membership.id
        assert_response 403
      end

      should "remove member" do
        login_as :johan

        assert_difference("@project.reload.content_memberships.count", -1) do
          delete :destroy, :project_id => @project.to_param, :id => @membership.id
        end
      end

      should "redirect back to project" do
        login_as :johan
        delete :destroy, :project_id => @project.to_param, :id => @membership.id
        assert_response :redirect
        assert_redirected_to :action => "index"
      end

      should "remove all members to make project public" do
        login_as :johan
        delete :destroy, :project_id => @project.to_param, :id => "all"
        assert_equal 0, @project.content_memberships.count
      end
    end
  end

  context "With private repos disabled" do
    should "redirect to index project" do
      Gitorious::Configuration.override("enable_private_repositories" => false) do
        login_as :moe
        id = projects(:moes).to_param
        get :index, :project_id => id
        assert_redirected_to :controller => "projects", :action => "show", :id => id
      end
    end
  end
end
