# encoding: utf-8
#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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

class CommittershipsControllerTest < ActionController::TestCase

  def setup
    @project = projects(:johans)
    @group = groups(:team_thunderbird)
    @user = users(:johan)
    @repository = repositories(:johans)
    login_as :johan
  end
  
  context "GET index" do
    should "requires login" do
      login_as nil
      get :index, :project_id => @project.to_param, :repository_id => @repository.to_param
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_redirected_to(project_repository_path(@project, @repository))
    end
    
    should "requires adminship" do
      @repository.owner = @group
      @repository.save
      @group.add_member(@user, Role.committer)
      get :index, :group_id => @group.to_param, :repository_id => @repository.to_param
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_redirected_to(group_repository_path(@group, @repository))
    end
    
    should "finds the owner (a Project) and the repository" do
      get :index, :project_id => @project.to_param, :repository_id => @repository.to_param
      assert_response :success
      assert_equal @project, assigns(:owner)
      assigns(:repository) == @repository
    end
    
    should "finds the owner (a Group) and the repository" do
      @repository.owner = @group
      @repository.save!
      @group.add_member(@user, Role.admin)
      get :index, :group_id => @group.to_param, :repository_id => @repository.to_param
      assert_response :success
      assert_equal @group, assigns(:owner)
      assigns(:repository) == @repository
    end
    
    should "finds the owner (a User) and the repository" do
      @repository.owner = @user
      @repository.save!
      get :index, :user_id => @user.to_param, :repository_id => @repository.to_param
      assert_response :success
      assert_equal @user, assigns(:owner)
      assigns(:repository) == @repository
    end
    
    should "lists the committerships" do
      repo = repositories(:moes)
      repo.owner = @group
      repo.save!
      @group.add_member(@user, Role.admin)
      get :index, :group_id => @group.to_param, :repository_id => repo.to_param
      assert_response :success
      assert_equal @group.committerships, assigns(:committerships)
    end
  end

  context "GET new" do
    should "is successful" do
      get :new, :project_id => @project.to_param, :repository_id => @repository.to_param
      assert_response :success
      assert_not_equal nil, assigns(:committership)
      assert_equal @repository, assigns(:committership).repository
      assert assigns(:committership).new_record?, 'assigns(:committership).new_record? should be true'
    end
  end
  
  context "POST create" do
    should "adds a group as participant" do
      assert_difference("@repository.committerships.count") do
        post :create, :project_id => @project.to_param, :repository_id => @repository.to_param,
              :group => {:name => @group.name}
      end
      assert_response :redirect
      assert !assigns(:committership).new_record?, 'new_record? should be false'
      assert_equal @group, assigns(:committership).committer
      assert_equal @user, assigns(:committership).creator
    end
  end
  
  context "autocomplete group name" do
    should "finds user by login" do
      post :auto_complete_for_group_name, :group => { :name => "thunder" }, :format => "js"
      assert_equal [groups(:team_thunderbird)], assigns(:groups)
    end
  end
  
  context "DELETE destroy" do
    should "requires login" do
      login_as nil
      delete :destroy, :project_id => @project.to_param, :repository_id => @repository.to_param,
        :id => Committership.first.id
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_redirected_to(project_repository_path(@project, @repository))
    end

    should "deletes the committership" do
      committership = @repository.committerships.create!({
        :committer => @group,
        :creator => @user
      })
      assert_difference("@repository.committerships.count", -1) do
        delete :destroy, :project_id => @project.to_param, :repository_id => @repository.to_param,
          :id => committership.id
      end
      assert_match(/team was removed as a committer/, flash[:notice])
      assert_response :redirect
    end
  end

end
