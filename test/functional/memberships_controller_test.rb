# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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


require File.dirname(__FILE__) + '/../test_helper'

class MembershipsControllerTest < ActionController::TestCase

  should_render_in_global_context

  should_enforce_ssl_for(:delete, :destroy)
  should_enforce_ssl_for(:get, :edit)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :new)
  should_enforce_ssl_for(:post, :auto_complete_for_user_login)
  should_enforce_ssl_for(:post, :create)
  should_enforce_ssl_for(:put, :update)

  context "Routing" do
    setup do
      @group = groups(:team_thunderbird)
    end

    should "recognizes routing like /+team-name/memberships" do
      assert_generates("/+#{@group.to_param}/memberships", {
        :controller => "memberships",
        :action => "index",
        :group_id => @group.to_param
      })
      assert_recognizes({
        :controller => "memberships",
        :action => "index",
        :group_id => @group.to_param
      }, {:path => "/+#{@group.to_param}/memberships", :method => :get})
    end

    should "recognizes routing like /+team-name/memberships/n" do
      membership = @group.memberships.first
      assert_generates("/+#{@group.to_param}/memberships/#{membership.to_param}", {
        :controller => "memberships",
        :action => "show",
        :group_id => @group.to_param,
        :id => membership.to_param
      })
      assert_recognizes({
        :controller => "memberships",
        :action => "show",
        :group_id => @group.to_param,
        :id => membership.to_param
      }, {:path => "/+#{@group.to_param}/memberships/#{membership.to_param}", :method => :get})
    end
  end

  context "MembershipsController" do
    setup do
      login_as :mike
      @group = groups(:team_thunderbird)
    end

    context "GET /groups/N/memberships.html" do
      should "gets the memberships successfully" do
        get :index, :group_id => @group.to_param
        assert_response :success
        assert_equal @group.memberships, assigns(:memberships)
      end

      should " not require adminship in index" do
        login_as :moe
        get :index, :group_id => @group.to_param
        assert_response :success
      end

      context "paginating memberships" do
        setup { @params = { :group_id => @group.to_param } }
        should_scope_pagination_to(:index, Membership)
      end
    end

    context "/groups/N/memberships/new and create" do
      should "requires group adminship on new" do
        login_as :moe
        get :new, :group_id => @group.to_param
        assert_redirected_to(new_sessions_path)
      end

      should "gets the membership successfully" do
        get :new, :group_id => @group.to_param
        assert_response :success
      end

      should "requires group adminship on create" do
        login_as :moe
        assert_no_difference('@group.memberships.count') do
          post :create, :group_id => @group.to_param, :membership => {:role_id => Role.admin.id},
            :user => {:login => users(:mike).login }
        end
        assert_redirected_to(new_sessions_path)
      end

      should "creates a new membership sucessfully" do
        user = users(:moe)
        assert !@group.members.include?(user)
        assert_difference('@group.memberships.count') do
          post :create, :group_id => @group.to_param, :membership => {:role_id => Role.admin.id},
            :user => {:login => user.login }
        end
        assert_redirected_to(group_memberships_path(@group))
      end

      should "handle validation errors" do
        assert_no_difference('@group.memberships.count') do
          post :create, :group_id => @group.to_param,
            :membership => {:role_id => Role.admin.id},
            :user => {:login => "no-such-user" }
        end
        assert_response :success
        assert_template "new"
        assert_match(/No user was found/, flash[:error])
        assert !assigns(:membership).valid?
      end
    end

    context "updating membership" do
      should "requires adminship on edit" do
        login_as :moe
        get :edit, :group_id => @group.to_param, :id =>  @group.memberships.first.to_param
        assert_redirected_to(new_sessions_path)
      end

      should "GETs edit" do
        membership = @group.memberships.first
        get :edit, :group_id => @group.to_param, :id => membership.to_param
        assert_response :success
        assert_equal membership, assigns(:membership)
      end

      should "requires adminship on update" do
        login_as :moe
        put :update, :group_id => @group.to_param, :id =>  @group.memberships.first.id,
          :membership => {}
        assert_redirected_to(new_sessions_path)
      end

      should "PUTs update updates the role of the user" do
        membership = @group.memberships.first
        put :update, :group_id => @group.to_param, :id => membership.id,
          :membership => {:role_id => Role.member.id}
        assert_equal Role.member, membership.reload.role
        assert_redirected_to(group_memberships_path(@group))
      end
    end

    context "DELETE membership" do
      should "requires adminship" do
        login_as :moe
        assert_no_difference('@group.memberships.count') do
          delete :destroy, :group_id => @group.to_param, :id => @group.memberships.first.to_param
        end
        assert_redirected_to(new_sessions_path)
      end

      should "deletes the membership" do
        assert_difference('@group.memberships.count', -1) do
          delete :destroy, :group_id => @group.to_param, :id => @group.memberships.first.to_param
        end
        assert_redirected_to(group_memberships_path(@group))
      end
    end

    context "autocomplete username" do
      should "finds user by login" do
        post :auto_complete_for_user_login, :group_id => groups(:team_thunderbird).to_param,
          :q => "mik", :format => "js"
        assert_equal [users(:mike)], assigns(:users)
      end
    end
  end

  def valid_membership(opts = {})
    {
      :user_id => users(:mike).id,
      :role_id => Role.member.id
    }
  end

end
