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

describe GroupsController, "Routing" do
  before(:each) do
    @group = groups(:johans_team_thunderbird)
  end
  
  it "recognizes routes starting with plus as teams/show/<name>" do
    route_for({
      :controller => "groups", 
      :action => "show", 
      :id => @group.to_param
    }).should == "/+#{@group.to_param}"
    
    params_from(:get, "/+#{@group.to_param}").should == {
      :controller => "groups", :action => "show", :id => @group.to_param
    }
  end
end

describe GroupsController do
  before(:each) do
    @group = groups(:johans_team_thunderbird)
  end
  
  describe "GET index" do
    it "it is successfull" do
      get :index
      response.should be_success
    end
  end
  
  describe "GET show" do
    it "finds the requested group" do
      get :show, :id => @group.to_param
      response.should be_success
      assigns(:group).should == @group
    end
  end
  
  describe "creating a group" do
    it "requires login" do
      get :new
      response.should redirect_to(new_sessions_path)
    end
    
    it "GETs new successfully" do
      login_as :mike
      get :new
      response.should be_success
    end
    
    it "POST create creates a new group" do
      login_as :mike
      proc {
        post :create, :group => {:name => "foo-hackers"},
          :project => {:slug => projects(:johans).slug}
      }.should change(Group, :count)
      flash[:success].should_not == nil
      Group.last.name.should == "foo-hackers"
      Group.last.members.should == [users(:mike)]
    end
    
    it "POST creates a new group with a project" do
      login_as :mike
      proc {
        post :create, :group => {:name => "foo-hackers"}, 
          :project => {:slug => projects(:johans).slug}
      }.should change(Group, :count)
      flash[:success].should_not == nil
      Group.last.project.should == projects(:johans)
    end
  end
end