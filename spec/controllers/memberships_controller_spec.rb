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

describe MembershipsController, "Routing" do
  before(:each) do
    @group = groups(:team_thunderbird)
  end
  
  it "recognizes routing like /+team-name/memberships" do
    route_for({
      :controller => "memberships", 
      :action => "index", 
      :group_id => @group.to_param
    }).should == "/+#{@group.to_param}/memberships"
    
    params_from(:get, "/+#{@group.to_param}/memberships").should == {
      :controller => "memberships", :action => "index", :group_id => @group.to_param
    }
  end
  
  it "recognizes routing like /+team-name/memberships/n" do
    membership = @group.memberships.first
    route_for({
      :controller => "memberships", 
      :action => "show", 
      :group_id => @group.to_param,
      :id => membership.to_param
    }).should == "/+#{@group.to_param}/memberships/#{membership.to_param}"
    
    params_from(:get, "/+#{@group.to_param}/memberships/#{membership.to_param}").should == {
      :controller => "memberships", 
      :action => "show", 
      :group_id => @group.to_param,
      :id => membership.to_param
    }
  end
end

describe MembershipsController do
  before(:each) do 
    login_as :mike
    @group = groups(:team_thunderbird)
  end
  
  describe "GET /groups/N/memberships.html" do    
    it "gets the memberships successfully" do
      get :index, :group_id => @group.to_param
      response.should be_success
      assigns(:memberships).should == @group.memberships
    end
    
    it "should not require adminship in index" do
      login_as :moe
      get :index, :group_id => @group.to_param
      response.should be_success
    end
  end
  
  describe "/groups/N/memberships/new and create" do
    it "requires group adminship on new" do
      login_as :moe
      get :new, :group_id => @group.to_param
      response.should redirect_to(new_sessions_path)
    end
    
    it "gets the membership successfully" do
      get :new, :group_id => @group.to_param
      response.should be_success
    end
    
    it "requires group adminship on create" do
      login_as :moe
      proc {
        post :create, :group_id => @group.to_param, :membership => {:role_id => Role.admin.id},
          :user => {:login => users(:mike).login }
      }.should_not change(@group.memberships, :count)
      response.should redirect_to(new_sessions_path)
    end
    
    it "creates a new membership sucessfully" do
      proc {
        post :create, :group_id => @group.to_param, :membership => {:role_id => Role.admin.id},
          :user => {:login => users(:mike).login }
        }.should change(@group.memberships, :count)
      response.should redirect_to(group_memberships_path(@group))
    end
  end
  
  describe "updating membership" do
    it "requires adminship on edit" do
      login_as :moe
      get :edit, :group_id => @group.to_param, :id =>  @group.memberships.first.to_param
      response.should redirect_to(new_sessions_path)
    end
    
    it "GETs edit" do
      membership = @group.memberships.first
      get :edit, :group_id => @group.to_param, :id => membership.to_param
      response.should be_success
      assigns(:membership).should == membership
    end
    
    it "requires adminship on update" do
      login_as :moe
      put :update, :group_id => @group.to_param, :id =>  @group.memberships.first.id,
        :membership => {}
      response.should redirect_to(new_sessions_path)
    end
    
    it "PUTs update updates the role of the user" do
      membership = @group.memberships.first
      put :update, :group_id => @group.to_param, :id => membership.id,
        :membership => {:role_id => Role.committer.id}
      membership.reload.role.should == Role.committer
      response.should redirect_to(group_memberships_path(@group))
    end
  end
  
  describe "DELETE membership" do
    it "requires adminship" do
      login_as :moe
      proc{
        delete :destroy, :group_id => @group.to_param, :id => @group.memberships.first.to_param
      }.should_not change(@group.memberships, :count)
      response.should redirect_to(new_sessions_path)
    end
    
    it "deletes the membership" do
      proc{
        delete :destroy, :group_id => @group.to_param, :id => @group.memberships.first.to_param
      }.should change(@group.memberships, :count)
      response.should redirect_to(group_memberships_path(@group))
    end
  end
  
  describe "autocomplete username" do
    it "finds user by login" do
      post :auto_complete_for_user_login, :group_id => groups(:team_thunderbird).to_param, 
        :user => { :login => "mik" }, :format => "js"
      assigns(:users).should == [users(:mike)]
    end
  end
  
  def valid_membership(opts = {})
    {
      :user_id => users(:mike).id,
      :role_id => Role.committer.id
    }
  end
  
end
