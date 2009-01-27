#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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

describe RepositoriesController, "index" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  it "gets all the projects repositories" do
    get :index, :project_id => @project.slug
    response.should be_success
    assigns(:repositories).should == @project.group.repositories
  end
end


describe RepositoriesController, "show" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  def do_get(repos)
    get :show, :project_id => @project.slug, :id => repos.name
  end
  
  it "GET projects/1/repositories/1 is successful" do
    repo = @project.repositories.first
    repo.stubs(:git).returns(stub_everything("git mock"))
    do_get repo
    response.should be_success
  end
  
  it "scopes GET :show to the project_id" do
    repo = repositories(:moes)
    repo.stubs(:git).returns(stub_everything("git mock"))
    do_get repo
    response.code.to_i.should == 404
  end
  
  it "counts the number of merge requests" do
    repo = @project.repositories.first
    repo.stubs(:git).returns(stub_everything("git mock"))
    do_get repo
  end
end

describe RepositoriesController, "show as XML" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  def do_get(repos)
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :show, :project_id => @project.slug, :id => repos.name
  end
  
  it "GET projects/1/repositories/1.xml is successful" do
    repo = @project.repositories.first
    repo.stubs(:has_commits?).returns(false)
    repo.stubs(:git).returns(stub_everything("git mock"))
    do_get repo
    response.should be_success
    response.body.should == repo.to_xml
  end
end

describe RepositoriesController, "clone" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_get()
    #get :new, :project_id => @project.slug, :id => @repository.name
    #get clone_project_repository_path(@project, @repository)
    get :clone, :project_id => @project.slug, :id => @repository.name
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_get
    response.should redirect_to(new_sessions_path)
  end
  
  it "GET projects/1/repositories/3/clone is successful" do
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(true)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_get
    flash[:error].should == nil
    response.should be_success
    assigns[:repository_to_clone].should == @repository
    assigns[:repository].should be_instance_of(Repository)
    assigns[:repository].name.should == "johan-clone"
  end
  
  it "redirects to new_account_key_path if no keys on user" do
    users(:johan).ssh_keys.destroy_all
    login_as :johan
    do_get
    response.should redirect_to(new_account_key_path)
  end
  
  it "redirects with a flash if repos can't be cloned" do
    login_as :johan
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(false)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_get
    response.should redirect_to(project_repository_path(@project, @repository))
    flash[:error].should match(/can't clone an empty/i)
  end
end

describe RepositoriesController, "create_clone" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_post(opts={})
    post(:create_clone, :project_id => @project.slug, :id => @repository.name,
      :repository => {:owner_type => "User"}.merge(opts))
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_post
    response.should redirect_to(new_sessions_path)
  end
  
  it "post projects/1/repositories/3/create_clone is successful" do
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(true)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_post(:name => "foo-clone")
    response.should be_redirect
  end
  
  it "post projects/1/repositories/3/create_clone is successful sets the owner to the user" do
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(true)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_post(:name => "foo-clone", :owner_type => "User")
    response.should be_redirect
    assigns(:repository).owner.should == users(:johan)
  end
  
  it "post projects/1/repositories/3/create_clone is successful sets the owner to the group" do
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(true)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_post(:name => "foo-clone", :owner_type => "Group", :owner_id => users(:johan).groups.first.id)
    response.should be_redirect
    assigns(:repository).owner.should == users(:johan).groups.first
  end
  
  it "redirects to new_account_key_path if no keys on user" do
    users(:johan).ssh_keys.destroy_all
    login_as :johan
    do_post
    response.should redirect_to(new_account_key_path)
  end
  
  it "redirects with a flash if repos can't be cloned" do
    login_as :johan
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(false)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_post(:name => "foobar")
    response.should redirect_to(project_repository_path(@project, @repository))
    flash[:error].should match(/can't clone an empty/i)
  end
end

describe RepositoriesController, "create_clone as XML" do
  
  before(:each) do
    authorize_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_post(opts={})
    @request.env["HTTP_ACCEPT"] = "application/xml"
    post(:create_clone, :project_id => @project.slug, :id => @repository.name,
      :repository => {:owner_type => "User"}.merge(opts))
  end
  
  it "should require login" do
    authorize_as(nil)
    do_post(:name => "foo")
    response.code.to_i.should == 401
  end
  
  it "post projects/1/repositories/3/create_copy is successful" do
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(true)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_post(:name => "foo-clone")
    response.code.to_i.should == 201
  end
  
  it "renders text if repos can't be cloned" do
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(false)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_post(:name => "foobar")
    response.code.to_i.should == 422
    response.body.should match(/can't clone an empty/i)
  end
end

describe RepositoriesController, "writable_by" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_get(options={})
    post(:writable_by, {:project_id => @project.slug, :id => @repository.name,
      :username => "johan"}.merge(options))
  end
  
  it "should not require login" do
    session[:user_id] = nil
    do_get :username => "johan"
    response.should_not redirect_to(new_sessions_path)
  end
  
  it "get projects/1/repositories/3/writable_by?username=johan is true" do
    do_get :username => "johan"
    response.should be_success
    response.body.should == "true"
  end
  
  it "get projects/1/repositories/2/writable_by?username=johan is false" do
    do_get :username => "johan", :project_id => projects(:moes).slug, 
      :id => projects(:moes).repositories.first.name
    response.should be_success
    response.body.should == "false"
  end
  
  it "get projects/1/repositories/2/writable_by?username=nonexistinguser is false" do
    do_get :username => "nonexistinguser"
    response.should be_success
    response.body.should == "false"
  end
end

describe RepositoriesController, "destroy" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  def do_delete(repos)
    delete :destroy, :project_id => @project.slug, :id => repos.name
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_delete(@project.repositories.first)
    response.should redirect_to(new_sessions_path)
  end
  
  it "can only be deleted by the owner" do
    login_as :johan
    @project.repositories.last.update_attribute(:user_id, users(:moe).id)
    do_delete(@project.repositories.last)
    response.should redirect_to(project_path(@project))
    flash[:error].should == "You're not the owner of this repository"
  end
  
  it "the owner can delete his own repos" do
    login_as :johan
    repo = repositories(:johans2)
    repo.user = users(:johan)
    repo.save!
    do_delete(repo)
    response.should redirect_to(project_path(@project))
    flash[:error].should == nil
    flash[:notice].should == "The repository was deleted"
  end
  
end

describe RepositoriesController, "with committer (not owner) logged in" do
  integrate_views
  
  before(:each) do
    login_as :mike
    @project = projects(:johans)
    @project.group.add_member(users(:mike), Role.committer)
    @repository = @project.repositories.first
  end
  
  def do_get()
    get :show, :project_id => @project.slug, :id => @repository.name
  end
    
  it "should GET projects/1/repositories/3 and have merge request link" do
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(true)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_get
    flash[:error].should == nil
    response.body.should match(/Request merge/)
  end
end