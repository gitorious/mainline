#--
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
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

describe CommittersController do
end

describe CommittersController, "new" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = repositories(:johans)
  end
  
  def do_get()
    get :new, :project_id => @project.slug, :repository_id => @repository.name
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_get
    response.should redirect_to(new_sessions_path)
  end
  
  it "GET projects/1/repositories/1/committers/new is successful" do
    do_get
    response.should be_success
  end
  
  it "only allows owner to add committers" do
    login_as :moe
    do_get
    response.should be_redirect
    flash[:error].should == "You're not the owner of this repository"
  end
end

describe CommittersController, "create" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = repositories(:johans)
    Committership.destroy_all
  end
  
  def do_post(data)
    post :create, :project_id => @project.slug, :repository_id => @repository.name,
          :user => data
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_post :login => "foo"
    response.should redirect_to(new_sessions_path)
  end
  
  it "POST projects/1/repositories/1/committers/create is successful" do
    users(:johan).can_write_to?(@repository).should == false
    do_post(:login => "johan")
    users(:johan).can_write_to?(@repository).should == true
    response.should be_redirect
  end
  
  it "only creates the committership if user isn't already a committer" do
    @repository.committers << users(:johan)
    @repository.save!
    perm_count = @repository.committerships.count
    do_post(:login => "johan")
    @repository.committerships.count.should == perm_count
  end
  
  it "redirects when theres no user found" do
    users(:johan).can_write_to?(@repository).should == false
    do_post(:login => "foo")
    users(:johan).can_write_to?(@repository).should == false
    response.should be_redirect
    flash[:error].should_not == nil
  end
end

describe CommittersController, "destroy" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = repositories(:johans)
    Committership.destroy_all
  end
  
  def do_delete(user_id)
    delete :destroy, :project_id => @project.slug, :repository_id => @repository.name,
          :id => user_id
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_delete 1
    response.should redirect_to(new_sessions_path)
  end

  it "DELETE projects/1/repositories/1/committers/create is successful" do
    @repository.committers << users(:johan)
    @repository.save!
    users(:johan).can_write_to?(@repository).should == true
    
    do_delete(users(:johan).id)
    response.should be_redirect
    flash[:success].should_not be(nil)
    users(:johan).can_write_to?(@repository).should == false
  end
end