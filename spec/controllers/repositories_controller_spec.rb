#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
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

describe RepositoriesController, "Routing" do
  before(:each) do
    @project = projects(:johans)
    @repo = repositories(:johans)
  end
  
  it "recognizes routing like /projectname/reponame" do
    params_from(:get, "/#{@project.to_param}/#{@repo.to_param}").should == {
      :controller => "repositories", 
      :action => "show", 
      :project_id => @project.to_param,
      :id => @repo.to_param,
    }
    params_from(:get, "/#{@project.to_param}/#{@repo.to_param}/merge_requests").should == {
      :controller => "merge_requests", 
      :action => "index", 
      :project_id => @project.to_param,
      :repository_id => @repo.to_param,
    }
    
    route_for({
      :controller => "repositories", 
      :action => "show", 
      :project_id => @project.to_param,
      :id => @repo.to_param,
    }).should == "/#{@project.to_param}/#{@repo.to_param}"
    
    route_for({
      :controller => "trees", 
      :action => "index", 
      :project_id => @project.to_param,
      :repository_id => @repo.to_param,
    }).should == "/#{@project.to_param}/#{@repo.to_param}/tree"
    
    route_for({
      :controller => "trees", 
      :action => "show", 
      :project_id => @project.to_param,
      :repository_id => @repo.to_param,
      :branch_and_path => %w[foo bar baz]
    }).should == "/#{@project.to_param}/#{@repo.to_param}/tree/foo/bar/baz"
  end
  
  it "recognizes routing like /projectname/repositories" do
    params_from(:get, "/#{@project.to_param}/repositories").should == {
      :controller => "repositories",
      :action => "index", 
      :project_id => @project.to_param
    }
    
    params_from(:get, "/#{@project.to_param}/repositories/").should == {
      :controller => "repositories",
      :action => "index", 
      :project_id => @project.to_param
    }
    route_for({
      :controller => "repositories", 
      :action => "index", 
      :project_id => @project.to_param
    }).should == "/#{@project.to_param}/repositories"
  end
  
  it "recognizes routing like /projectname/reponame, with a non-html format" do
    params_from(:get, "/#{@project.to_param}/#{@repo.to_param}.xml").should == {
      :controller => "repositories", 
      :action => "show", 
      :project_id => @project.to_param,
      :format => "xml",
      :id => @repo.to_param,
    }
    params_from(:get, "/#{@project.to_param}/#{@repo.to_param}/merge_requests.xml").should == {
      :controller => "merge_requests", 
      :action => "index", 
      :format => "xml",
      :project_id => @project.to_param,
      :repository_id => @repo.to_param,
    }
    
    route_for({
      :controller => "repositories", 
      :action => "show", 
      :project_id => @project.to_param,
      :id => @repo.to_param,
      :format => "xml",
    }).should == "/#{@project.to_param}/#{@repo.to_param}.xml"
    
    route_for({
      :controller => "merge_requests", 
      :action => "index", 
      :project_id => @project.to_param,
      :repository_id => @repo.to_param,
    }).should == "/#{@project.to_param}/#{@repo.to_param}/merge_requests"
  end
  
  it "recognizes routing like /projectname/repositories, with a non-html format" do
    params_from(:get, "/#{@project.to_param}/repositories.xml").should == {
      :controller => "repositories",
      :action => "index", 
      :format => "xml",
      :project_id => @project.to_param
    }
    
    route_for({
      :controller => "repositories", 
      :action => "index", 
      :project_id => @project.to_param,
      :format => "xml",
    }).should == "/#{@project.to_param}/repositories.xml"
  end
  
  it "recognizes routing like /~username/repositories" do
    user = users(:johan)
    params_from(:get, "/~#{user.to_param}/repositories").should == {
      :controller => "repositories",
      :action => "index", 
      :user_id => user.to_param
    }
    
    route_for({
      :controller => "repositories", 
      :action => "index", 
      :user_id => user.to_param,
    }).should == "/~#{user.to_param}/repositories"
  end
  
  it "recognizes routing like /~username/repositories, with a non-html format" do
    user = users(:johan)
    params_from(:get, "/~#{user.to_param}/repositories.xml").should == {
      :controller => "repositories",
      :action => "index", 
      :format => "xml",
      :user_id => user.to_param
    }
    
    route_for({
      :controller => "repositories", 
      :action => "index", 
      :user_id => user.to_param,
      :format => "xml",
    }).should == "/~#{user.to_param}/repositories.xml"
  end
  
  it "recognizes routing like /+teamname/repositories" do
    team = groups(:team_thunderbird)
    params_from(:get, "/+#{team.to_param}/repositories").should == {
      :controller => "repositories",
      :action => "index", 
      :group_id => team.to_param
    }
    
    route_for({
      :controller => "repositories", 
      :action => "index", 
      :group_id => team.to_param,
    }).should == "/+#{team.to_param}/repositories"
  end
  
  it "recognizes routing like /+teamname/repositories, with a non-html format" do
    team = groups(:team_thunderbird)
    params_from(:get, "/+#{team.to_param}/repositories.xml").should == {
      :controller => "repositories",
      :action => "index", 
      :format => "xml",
      :group_id => team.to_param
    }
    
    route_for({
      :controller => "repositories", 
      :action => "index", 
      :group_id => team.to_param,
      :format => "xml",
    }).should == "/+#{team.to_param}/repositories.xml"
  end
end

describe RepositoriesController, "index" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  it "gets all the projects repositories" do
    get :index, :project_id => @project.slug
    response.should be_success
    assigns(:repositories).should == @project.repositories
  end
end

describe RepositoriesController, "showing a user namespaced repo" do
  before(:each) do
    @user = users(:johan)
  end
  
  it "GET users/johan/repositories/foo is successful" do
    repo = @user.repositories.first
    repo.stubs(:git).returns(stub_everything("git mock"))
    get :show, :user_id => @user.to_param, :id => repo.to_param
    response.should be_success
    assigns(:owner).should == @user
  end
end

describe RepositoriesController, "showing a team namespaced repo" do
  before(:each) do
    @group = groups(:team_thunderbird)
  end
  
  it "GET teams/foo/repositories/bar is successful" do
    repo = @group.repositories.first
    repo.stubs(:git).returns(stub_everything("git mock"))
    get :show, :group_id => @group.to_param, :id => repo.to_param
    response.should be_success
    assigns(:owner).should == @group
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
  
  it "issues a Refresh header if repo isn't ready yet" do
    repo = @project.repositories.first
    repo.stubs(:ready).returns(false)
    do_get repo
    response.should be_success
    response.headers['Refresh'].should_not be_nil
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
    groups(:team_thunderbird).add_member(users(:johan), Role.admin)
    Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
    @repository.stubs(:has_commits?).returns(true)
    @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
    do_post(:name => "foo-clone", :owner_type => "Group", :owner_id => groups(:team_thunderbird).id)
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
    response.body.should == "true #{@repository.real_gitdir}"
  end
  
  it "get projects/1/repositories/2/writable_by?username=johan is false" do
    do_get :username => "johan", :project_id => projects(:moes).slug, 
      :id => projects(:moes).repositories.first.name
    response.should be_success
    response.body.should == "false nil"
  end
  
  it "get projects/1/repositories/2/writable_by?username=nonexistinguser is false" do
    do_get :username => "nonexistinguser"
    response.should be_success
    response.body.should == "false nil"
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
    delete :destroy, :group_id => repo.owner.to_param, :id => repo.to_param
    flash[:error].should == nil
    flash[:notice].should == "The repository was deleted"
    response.should redirect_to(group_path(repo.owner))
  end
  
  it "destroying a project creates an event in the project" do
    login_as :johan
    repo = repositories(:johans2)
    repo.user = users(:johan)
    repo.save!
    proc {
      delete :destroy, :group_id => repo.owner.to_param, :id => repo.to_param
    }.should change(repo.project.events, :count)
        
  end
end

describe RepositoriesController, "new / create" do
  before(:each) do
    @project = projects(:johans)
    @user = users(:johan)
    @group = groups(:team_thunderbird)
    @group.add_member(@user, Role.admin)
    login_as :johan
  end
  
  it "should require login" do
    login_as nil
    get :new, :project_id => @project.to_param
    response.should redirect_to(new_sessions_path)
  end
  
  it "should require adminship" do
    login_as :moe
    get :new, :project_id => @project.to_param
    flash[:error].should match(/only repository admins are allowed/)
    response.should redirect_to(project_path(@project))
    
    post :create, :project_id => @project.to_param, :repository => {}
    flash[:error].should match(/only repository admins are allowed/)
    response.should redirect_to(project_path(@project))
  end
  
  it "should only be allowed to add new repositories to Project" do 
    get :new, :group_id => @group.to_param
    flash[:error].should match(/can only add new repositories directly to a project/)
    response.should redirect_to(group_path(@group))
    
    get :new, :user_id => @user.to_param
    flash[:error].should match(/can only add new repositories directly to a project/)
    response.should redirect_to(user_path(@user))
    
    post :create, :group_id => @group.to_param, :repository => {}
    flash[:error].should match(/can only add new repositories directly to a project/)
    response.should redirect_to(group_path(@group))
    
    post :create, :user_id => @user.to_param, :repository => {}
    flash[:error].should match(/can only add new repositories directly to a project/)
    response.should redirect_to(user_path(@user))
  end
  
  # See example "should only be allowed to add new repositories to Project"
  # for why this is commented out
  # 
  # it "should GET new successfully, and set the owner to a user" do
  #   get :new, :user_id => @user.to_param
  #   response.should be_success
  #   assigns(:owner).should == @user
  # end
  # 
  # it "should GET new successfully, and set the owner to a group" do
  #   get :new, :group_id => @group.to_param
  #   response.should be_success
  #   assigns(:owner).should == @group
  # end
  # 
  # it "creates a new repository belonging to a user" do
  #   proc {
  #     post :create, :user_id => @user.to_param, :repository => {:name => "my-new-repo"}
  #   }.should change(Repository, :count)
  #   assigns(:repository).owner.should == @user
  #   response.should be_redirect
  #   response.should redirect_to(user_repository_path(@user, assigns(:repository)))
  # end
  # 
  # it "creates a new repository belonging to a group" do
  #   proc {
  #     post :create, :group_id => @group.to_param, :repository => {:name => "my-new-repo"}
  #   }.should change(Repository, :count)
  #   assigns(:repository).owner.should == @group
  #   response.should be_redirect
  #   response.should redirect_to(group_repository_path(@group, assigns(:repository)))
  # end
  
  it "should GET new successfully, and set the owner to a project" do
    get :new, :project_id => @project.to_param
    response.should be_success
    assigns(:owner).should == @project
  end
  
  it "creates a new repository belonging to a Project" do
    proc {
      post :create, :project_id => @project.to_param, :repository => {:name => "my-new-repo"}
    }.should change(Repository, :count)
    assigns(:repository).owner.should == @project
    response.should be_redirect
    response.should redirect_to(project_repository_path(@project, assigns(:repository)))
  end
end

describe RepositoriesController, "edit / update" do
  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
    login_as :johan
    groups(:team_thunderbird).add_member(users(:johan), Role.admin)
  end
  
  it "requires login" do
    login_as nil
    get :edit, :project_id => @project.to_param, :id => @repository.to_param
    response.should redirect_to(new_sessions_path)
    
    put :update, :project_id => @project.to_param, :id => @repository.to_param
    response.should redirect_to(new_sessions_path)
  end
    
  it "requires adminship on the project if owner is a project" do
    login_as :moe
    get :edit, :project_id => @project.to_param, :id => @repository.to_param
    flash[:error].should match(/only repository admins are allowed/)
    response.should redirect_to(project_path(@project))
  end
    
  it "requires adminship on the user if owner is a user" do
    login_as :moe
    @repository.owner = users(:moe)
    @repository.save!
    get :edit, :user_id => users(:moe).to_param, :id => @repository.to_param
    response.should be_success
  end
    
  it "requires adminship on the group, if the owner is a group" do
    login_as :mike
    @repository.owner = groups(:team_thunderbird)
    @repository.save!
    get :edit, :group_id => groups(:team_thunderbird).to_param, :id => @repository.to_param
    response.should be_success
  end
  
  it "GETs edit/n successfully" do
    get :edit, :project_id => @project.to_param, :id => @repository.to_param
    response.should be_success
    assigns(:repository).should == @repository
  end
  
  it "PUT update successfully" do
    put :update, :project_id => @project.to_param, :id => @repository.to_param,
      :repository => {:description => "blablabla"}
    response.should redirect_to(project_repository_path(@project, @repository))
    @repository.reload.description.should == "blablabla"
  end
  
  it "gets a list of the users' groups on edit" do
    get :edit, :project_id => @project.to_param, :id => @repository.to_param
    response.should be_success
    assigns(:groups).should == users(:johan).groups
  end
  
  it "gets a list of the users' groups on update" do
    put :update, :project_id => @project.to_param, :id => @repository.to_param, 
          :repository => {:description => "foo"}
    assigns(:groups).should == users(:johan).groups
  end
  
  it "changes the owner" do
    group = groups(:team_thunderbird)
    put :update, :project_id => @project.to_param, :id => @repository.to_param, :repository => {
      :owner_id => group.id,
    }
    response.should redirect_to(group_repository_path(group, @repository))
    @repository.reload.owner.should == group
  end
  
  it "changes the owner, only if the original owner was a user" do
    group = groups(:team_thunderbird)
    @repository.owner = group
    @repository.save!
    new_group = Group.create!(:name => "temp")
    new_group.add_member(users(:johan), Role.admin)
    
    put :update, :group_id => group.to_param, :id => @repository.to_param, :repository => {
      :owner_id => new_group.id
    }
    @repository.reload.owner.should == group
    response.should redirect_to(group_repository_path(group, @repository))
  end
end

describe RepositoriesController, "with committer (not owner) logged in" do
  integrate_views
    
  it "should GET projects/1/repositories/3 and have merge request link" do
    login_as :mike
    project = projects(:johans)
    project.owner = groups(:team_thunderbird)
    project.owner.add_member(users(:mike), Role.committer)
    project.save!
    repository = project.repositories.first
    Project.expects(:find_by_slug!).with(project.slug).returns(project)
    repository.stubs(:has_commits?).returns(true)
    
    get :show, :project_id => project.to_param, :id => repository.to_param
    flash[:error].should == nil
    response.body.should match(/Request merge/)
  end
end