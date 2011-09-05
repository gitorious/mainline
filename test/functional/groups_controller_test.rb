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

require File.dirname(__FILE__) + "/../test_helper"

class GroupsControllerTest < ActionController::TestCase

  should_render_in_global_context

  def setup
    @group = groups(:team_thunderbird)
  end

  should_enforce_ssl_for(:delete, :avatar)
  should_enforce_ssl_for(:delete, :destroy)
  should_enforce_ssl_for(:get, :edit)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :new)
  should_enforce_ssl_for(:get, :show)
  should_enforce_ssl_for(:post, :create)
  should_enforce_ssl_for(:put, :update)

  context "Routing" do
    should "recognizes routes starting with plus as teams/show/<name>" do
      assert_generates("/+#{@group.to_param}", { :controller => "groups",
        :action => "show", :id => @group.to_param})
      assert_recognizes({:controller => "groups", :action => "show",
                         :id => @group.to_param}, "/+#{@group.to_param}")
    end
  end

  context "index" do
    should "GET successfully" do
      get :index
      assert_response :success
    end

    context "teams pagination" do
      should_scope_pagination_to(:index, Group, "teams")
    end
  end

  context "show" do
    should "find the requested group" do
      get :show, :id => @group.to_param
      assert_response :success
      assert_equal @group, assigns(:group)
    end

    context "pagination" do
      setup { @params = { :id => @group.to_param } }
      should_scope_pagination_to(:show, Event)
    end
  end

  context "edit" do
    setup do
      login_as :mike
      get :edit, :id => @group.to_param
    end

    should_assign_to :group
    should_respond_with :success
  end

  context "update" do
    should "require user to be admin of group" do
      put :update, :id => @group.to_param, :group => {:description => "Unskilled and unprofessional"}
      assert_redirected_to :controller => "sessions", :action => "new"
    end

    should "only update the description, not the name" do
      login_as :mike
      put :update, :id => @group.to_param, :group => {:name => "hackers"}
      assert_redirected_to :action => "show"
      assert_equal("team-thunderbird", @group.name)
    end

    should "update successfully" do
      login_as :mike
      new_description = "We save lives"
      put :update, :id => @group.to_param, :group => {:description => new_description}
      assert_redirected_to :action => "show"
      assert_equal(new_description, @group.reload.description)
    end
  end

  context "creating a group" do
    should "require login" do
      get :new
      assert_redirected_to (new_sessions_path)
    end

    should "GET new successfully" do
      login_as :mike
      get :new
      assert_response :success
    end

    should "POST to create a new group" do
      login_as :mike

      assert_difference("Group.count") do
        post :create, :group => {:name => "foo-hackers", :description => "Hacking the foos for your bars"},
          :project => {:slug => projects(:johans).slug}
      end

      assert_not_equal nil, flash[:success]
      assert !assigns(:group).new_record?, "assigns(:group).new_record? should be false"
      assert_equal "foo-hackers", assigns(:group).name
      assert_equal [users(:mike)], assigns(:group).members
    end
  end

  context "deleting a group" do
    setup do
      @group = groups(:team_thunderbird)
      @user = users(:mike)
      assert @group.admin?(@user)
    end

    should "succeed if there is only one member" do
      assert_equal 1, @group.members.count
      login_as :mike
      @group.projects.destroy_all

      assert_difference("Group.count", -1) do
        delete :destroy, :id => @group.to_param
        assert_response :redirect
      end
      assert_redirected_to groups_path
      assert_match(/team was deleted/, flash[:success])
    end

    should "fail if there is more than one member" do
      @group.add_member(users(:johan), Role.member)
      assert_equal 2, @group.members.count
      login_as :mike
      assert_no_difference("Group.count", -1) do
        delete :destroy, :id => @group.to_param
        assert_response :redirect
      end
      assert_redirected_to group_path(@group)
      assert_match(/team cannot be deleted/, flash[:error])
    end

    should "succeed if there is more than one member and user is site_admin" do
      assert users(:johan).site_admin?
      @group.add_member(users(:johan), Role.member)
      assert_equal 2, @group.members.count

      login_as :johan
      assert_difference("Group.count", -1) do
        delete :destroy, :id => @group.to_param
      end
      assert_response :redirect
      assert_redirected_to groups_path
      assert_match(/team was deleted/, flash[:success])
    end

    should "successfully remove the team avatar" do
      login_as :mike
      @group.update_attribute(:avatar_file_name, "foo.png")
      assert @group.avatar?
      delete :avatar, :id => @group.to_param
      assert_redirected_to group_path(@group)
      assert !@group.reload.avatar?
    end
  end
end
