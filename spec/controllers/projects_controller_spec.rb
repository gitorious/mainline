#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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

describe ProjectsController do
  before(:each) do
    @projects = [mock_model(Project), mock_model(Project)]
  end
  
  def url_path(path, host="http://test.host")
    "#{host}#{path}"
  end
  
  it "GET projects/ should be succesful" do
    Project.should_receive(:find).and_return(@projects)
    get :index
    response.should be_success
    assigns(:projects).should == @projects
    response.should render_template("index")
  end
  
  it "GET projects/new should be succesful" do
    login_as :johan
    get :new
    response.should be_success
    response.should render_template("new")
  end
  
  it "GET projects/new should redirect to new_account_key_path if no keys on user" do
    users(:johan).ssh_keys.destroy_all
    login_as :johan
    get :new
    response.should redirect_to(new_account_key_path)
  end
  
  it "GET projects/new should require login" do
    get :new
    response.should be_redirect
    response.should redirect_to(new_sessions_path)
  end
  
  it "POST projects/create with valid data should create project" do
    login_as :johan
    post :create, :project => {:title => "project x", :slug => "projectx", :description => "projectx's description"}
    response.should be_redirect
    response.should redirect_to(projects_path)
    
    Project.find_by_title("project x").user.should == users(:johan)
  end
  
  it "GET projects/create should redirect to new_account_key_path if no keys on user" do
    users(:johan).ssh_keys.destroy_all
    login_as :johan
    post :create
    response.should redirect_to(new_account_key_path)
  end
  
  it "projects/create should require login" do
    post :create
    response.should redirect_to(new_sessions_path)
  end
  
  it "PUT projects/update should require login" do
    put :update
    response.should redirect_to(new_sessions_path)
  end
  
  it "PUT projects/update can only be done by project owner" do
    login_as :moe
    put :update, :id => projects(:johans).slug, :project => {:title => "new name", :slug => "foo", :description => "bar"}
    flash[:error].should match(/you're not the owner of this project/i)
    response.should redirect_to(project_path(projects(:johans)))
  end
  
  it "PUT projects/update with valid data should update record" do
    login_as :johan
    project = projects(:johans)
    put :update, :id => project.slug, :project => {:title => "new name", :slug => "foo", :description => "bar"}
    assigns(:project).should == project
    response.should be_redirect
    response.should redirect_to(project_path(project.reload))
    project.reload.title.should == "new name"
  end
  
  it "DELETE projects/destroy should require login" do
    delete :destroy
    response.should be_redirect
    response.should redirect_to(url_path(new_sessions_path))
  end
  
  it "DELETE projects/xx is only allowed by project owner" do
    login_as :moe
    delete :destroy, :id => projects(:johans).slug
    response.should redirect_to(projects_path)
    flash[:error].should match(/You're not the owner of this project, or the project has clones/i)
  end
  
  it "DELETE projects/xx is only allowed if there's a single repository (mainline)" do
    login_as :johan
    delete :destroy, :id => projects(:johans).slug
    response.should redirect_to(projects_path)
    flash[:error].should match(/You're not the owner of this project, or the project has clones/i)
    Project.find_by_id(1).should_not == nil    
  end
  
  it "DELETE projects/destroy should destroy the project" do
    login_as :johan
    projects(:johans).repositories.last.destroy
    delete :destroy, :id => projects(:johans).slug
    response.should redirect_to(projects_path)
    Project.find_by_id(1).should == nil
  end
  
  it "GET projects/show should be success" do
    get :show, :id => projects(:johans).slug
    assigns[:project].should == projects(:johans)
    response.should be_success
  end
  
  it "GET projects/show should fetch the repositories for a project" do
    get :show, :id => projects(:johans).slug
    assigns[:repositories].should == (projects(:johans).repositories - [repositories(:johans)])
    assigns[:mainline_repository].should == repositories(:johans)
    response.should be_success
  end

  it "GET projects/xx/edit should require login" do
    get :edit, :id => projects(:johans).slug
    response.should be_redirect
    response.should redirect_to(new_sessions_path)
  end

  it "GET projects/xx/edit should be a-ok" do
    login_as(:johan)
    get :edit, :id => projects(:johans).slug
    response.should be_success
  end

  it "GET projects/xx/confirm_delete should require login" do
    get :confirm_delete
    response.should be_redirect
    response.should redirect_to(new_sessions_path)
  end
  
  it "GET projects/xx/confirm_delete fetches the project" do
    login_as(:johan)
    get :edit, :id => projects(:johans).slug
    response.should be_success
    assigns[:project].should == projects(:johans)
  end
end

describe ProjectsController, "in Private Mode" do
  before(:each) do
    GitoriousConfig['public_mode'] = false
  end
  
  after(:each) do
    GitoriousConfig['public_mode'] = true
  end
  
  it "GET /projects" do
    get :index
    response.should redirect_to(root_path)
    flash[:error].should match(/Action requires login/)
  end
end