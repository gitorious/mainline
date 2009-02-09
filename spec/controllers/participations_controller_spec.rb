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

require File.dirname(__FILE__) + '/../spec_helper'

describe ParticipationsController do
  before(:each) do
    @project = projects(:johans)
    @group = groups(:team_thunderbird)
    @user = users(:johan)
    @repository = repositories(:johans)
    login_as :johan
  end
  
  describe "GET index" do    
    it "requires login" do
      login_as nil
      get :index, :project_id => @project.to_param, :repository_id => @repository.to_param
      flash[:error].should match(/only repository admins are allowed/)
      response.should redirect_to(project_repository_path(@project, @repository))
    end
    
    it "requires adminship" do
      @repository.owner = @group
      @repository.save
      @group.add_member(@user, Role.committer)
      get :index, :group_id => @group.to_param, :repository_id => @repository.to_param
      flash[:error].should match(/only repository admins are allowed/)
      response.should redirect_to(group_repository_path(@group, @repository))
    end
    
    it "finds the owner (a Project) and the repository" do
      get :index, :project_id => @project.to_param, :repository_id => @repository.to_param
      response.should be_success
      assigns(:owner).should == @project
      assigns(:repository) == @repository
    end
    
    it "finds the owner (a Group) and the repository" do
      @repository.owner = @group
      @repository.save!
      @group.add_member(@user, Role.admin)
      get :index, :group_id => @group.to_param, :repository_id => @repository.to_param
      response.should be_success
      assigns(:owner).should == @group
      assigns(:repository) == @repository
    end
    
    it "finds the owner (a User) and the repository" do
      @repository.owner = @user
      @repository.save!
      get :index, :user_id => @user.to_param, :repository_id => @repository.to_param
      response.should be_success
      assigns(:owner).should == @user
      assigns(:repository) == @repository
    end
    
    it "lists the participations" do
      repo = repositories(:moes)
      repo.owner = @group
      repo.save!
      @group.add_member(@user, Role.admin)
      get :index, :group_id => @group.to_param, :repository_id => repo.to_param
      response.should be_success
      assigns(:participations).should == @group.participations
    end
  end

  describe "GET new" do
    it "is successful" do
      get :new, :project_id => @project.to_param, :repository_id => @repository.to_param
      response.should be_success
      assigns(:participation).should_not == nil
      assigns(:participation).repository.should == @repository
      assigns(:participation).new_record?.should == true
    end
  end
  
  describe "POST create" do
    it "adds a group as participant" do
      proc {
        post :create, :project_id => @project.to_param, :repository_id => @repository.to_param,
              :group => {:name => @group.name}
      }.should change(@repository.participations, :count)
      response.should be_redirect
      assigns(:participation).should_not be_new_record
      assigns(:participation).group.should == @group
      assigns(:participation).creator.should == @user
    end
  end
  
  describe "autocomplete group name" do
    it "finds user by login" do
      post :auto_complete_for_group_name, :group => { :name => "thunder" }, :format => "js"
      assigns(:groups).should == [groups(:team_thunderbird)]
    end
  end
  
  describe "DELETE destroy" do
    it "requires login" do
      login_as nil
      delete :destroy, :project_id => @project.to_param, :repository_id => @repository.to_param,
        :id => Participation.first.id
      flash[:error].should match(/only repository admins are allowed/)
      response.should redirect_to(project_repository_path(@project, @repository))
    end

    it "deletes the participation" do
      participation = @repository.participations.create!({
        :group => @group,
        :creator => @user
      })
      proc {
        delete :destroy, :project_id => @project.to_param, :repository_id => @repository.to_param,
          :id => participation.id
      }.should change(@repository.participations, :count)
      flash[:notice].should match(/team was removed as a committer/)
      response.should be_redirect
    end
  end

end
