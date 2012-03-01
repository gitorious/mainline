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

require File.dirname(__FILE__) + "/../test_helper"

class RepositoryMembershipsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context :only => [:index]
  should_enforce_ssl_for(:delete, :destroy)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:post, :create)
  should_enforce_ssl_for(:put, :update)

  def setup
    setup_ssl_from_config
    @repository = repositories(:johans)
    @user = users(:johan)
  end

  context "With private repos" do
    setup do
      enable_private_repositories
      GitoriousConfig["use_ssl"] = false
    end

    context "index" do
      should "reject unauthorized user from listing memberships" do
        login_as :mike
        get :index, params
        assert_response 403
      end

      should "allow owner to manage access" do
        login_as :johan
        get :index, params
        assert_response 200
      end

      should "state that repository is public" do
        login_as :moe
        @repository = repositories(:moes)
        get :index, params

        assert_response 200
        assert_match /Repository is open/, @response.body
        assert_match /Make private/, @response.body
      end
    end

    context "create" do
      should "reject anonymous user" do
        login = @user.login
        post :create, params(:user => { :login => login })
        assert_response 302
      end

      should "explicitly add owner as collaborator" do
        login = @user.login
        login_as :johan

        assert_difference("@repository.reload.content_memberships.count") do
          post :create, params(:user => { :login => login })
        end
      end

      should "default to adding owner if no parameters" do
        login_as :johan

        assert_difference("@repository.reload.content_memberships.count") do
          post :create, params
        end

        assert_equal @user, @repository.content_memberships.first.member
      end

      should "add group as collaborator" do
        team = groups(:a_team)
        login_as :johan

        assert_difference("@repository.reload.content_memberships.count") do
          post :create, params(:group => { :name => team.name }, :user => { :login => "" })
        end

        assert can_read?(team, @repository)
      end

      should "redirect back to index" do
        login = @user.login
        login_as :johan

        post :create, params(:user => { :login => login }, :group => { :name => "" })
        assert_response :redirect
        assert_redirected_to :action => "index"
      end

      should "render index if user can not be found" do
        login_as :johan
        post :create, params(:user => { :login => "login" })

        assert_response 200
        assert_template "index"
        assert_match /No such user 'login'/, flash[:error]
      end

      should "render index if group can not be found" do
        login_as :johan
        post :create, params(:group => { :name => "login" })

        assert_response 200
        assert_template "index"
        assert_match /No such group 'login'/, flash[:error]
      end
    end

    context "destroy" do
      setup do
        @membership = @repository.content_memberships.first
      end

      should "reject unauthorized user" do
        login_as :moe
        delete :destroy, params(:id => @membership.id)
        assert_response 403
      end

      should "remove member" do
        login_as :johan

        assert_difference("@repository.reload.content_memberships.count", -1) do
          delete :destroy, params(:id => @membership.id)
        end
      end

      should "redirect back to repository" do
        login_as :johan
        delete :destroy, params(:id => @membership.id)
        assert_response :redirect
        assert_redirected_to :action => "index"
      end

      should "remove all members to make repository public" do
        login_as :johan
        delete :destroy, params(:id => "all")
        assert_equal 0, @repository.content_memberships.count
      end
    end
  end

  context "With private repos disabled" do
    setup do
      GitoriousConfig["enable_private_repositories"] = false
    end

    should "redirect to repository index" do
      login_as :moe
      @repository = repositories(:moes)
      get :index, params
      assert_redirected_to :controller => "repositories", :action => "show", :id => @repository.to_param
    end
  end

  protected
  def params(data = {})
    { :project_id => @repository.project.to_param,
      :repository_id => @repository.to_param }.merge(data)
  end
end
