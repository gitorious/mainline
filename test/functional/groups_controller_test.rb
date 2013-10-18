# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

require "test_helper"

class GroupsControllerTest < ActionController::TestCase
  should_render_in_global_context

  def setup
    setup_ssl_from_config
    @group = groups(:team_thunderbird)
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
      assert_match @group.name, @response.body
    end

    context "pagination" do
      setup { @params = { :id => @group.to_param } }
      should_scope_pagination_to(:show, Event)
    end
  end

  should "GET edit" do
    login_as :mike
    get :edit, :id => @group.to_param

    assert_match @group.name, @response.body
    assert_response :success
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
      assert_redirected_to new_sessions_path
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
      group = Group.last
      assert_equal "foo-hackers", group.name
      assert_equal [users(:mike)], group.members
    end

    should "validate on create" do
      login_as :mike
      post(:create, :group => {:name => "test test", :description => "Whatever"},
             :project => {:slug => projects(:johans).slug})
      assert_response :success
    end
  end

  context "deleting a group" do
    setup do
      @group = groups(:team_thunderbird)
      @user = users(:mike)
      assert admin?(@user, @group)
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
      assert_match(/Teams with current members or projects cannot be deleted/, flash[:error])
    end

    should "succeed if there is more than one member and user is site_admin" do
      assert site_admin?(users(:johan))
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

  context "when only admins are allowed to create new teams" do
    setup do
      users(:johan).update_attribute(:is_admin, true)
      users(:moe).update_attribute(:is_admin, false)
    end

    should "redirect on new" do
      Gitorious::Configuration.override("only_site_admins_can_create_teams" => true) do
        login_as :moe
        get :new
        assert_response :redirect
        assert_redirected_to :action => "index"
      end
    end

    should "succeed on new" do
      Gitorious::Configuration.override("only_site_admins_can_create_teams" => true) do
        login_as :johan
        get :new
        assert_response :success
      end
    end

    should "display the create link for site admins" do
      Gitorious::Configuration.override("only_site_admins_can_create_teams" => true) do
        login_as :johan
        get :index
        assert_response :success
        assert_select ".btn-primary .icon-plus-sign"
      end
    end

    should "not display the create link for non-admins" do
      Gitorious::Configuration.override("only_site_admins_can_create_teams" => true) do
        login_as :moe
        get :index
        assert_select ".btn-primary .icon-plus-sign", false
      end
    end
  end
end
