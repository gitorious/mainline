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


require File.dirname(__FILE__) + '/../test_helper'

class RepositoriesControllerTest < ActionController::TestCase

  def setup
    @project = projects(:johans)
    @repo = repositories(:johans)
  end
  
  should_render_in_site_specific_context :except => :writable_by
  
  context "Routing, by projects" do
    should "recognizes routing like /projectname/reponame" do
      assert_recognizes({
        :controller => "repositories", 
        :action => "show", 
        :project_id => @project.to_param,
        :id => @repo.to_param,
      }, {:path => "/#{@project.to_param}/#{@repo.to_param}", :method => :get})
      assert_recognizes({
        :controller => "merge_requests", 
        :action => "index", 
        :project_id => @project.to_param,
        :repository_id => @repo.to_param,
      }, {:path => "/#{@project.to_param}/#{@repo.to_param}/merge_requests", :method => :get})
      assert_generates("/#{@project.to_param}/#{@repo.to_param}", {
        :controller => "repositories", 
        :action => "show", 
        :project_id => @project.to_param,
        :id => @repo.to_param,
      })
    
      assert_generates("/#{@project.to_param}/#{@repo.to_param}/trees", {
        :controller => "trees", 
        :action => "index", 
        :project_id => @project.to_param,
        :repository_id => @repo.to_param,
      })

      assert_generates("/#{@project.to_param}/#{@repo.to_param}/trees/foo/bar/baz", {
        :controller => "trees", 
        :action => "show", 
        :project_id => @project.to_param,
        :repository_id => @repo.to_param,
        :branch_and_path => %w[foo bar baz]
      })
    end

    should "recognizes routing like /projectname/repositories" do
      assert_recognizes({
        :controller => "repositories",
        :action => "index", 
        :project_id => @project.to_param
      }, "/#{@project.to_param}/repositories")
  
      assert_recognizes({
        :controller => "repositories",
        :action => "index", 
        :project_id => @project.to_param
      }, "/#{@project.to_param}/repositories/")
      assert_generates("/#{@project.to_param}/repositories", {
        :controller => "repositories", 
        :action => "index", 
        :project_id => @project.to_param
      })
    end

    should "recognizes routing like /projectname/reponame, with a non-html format" do
      assert_recognizes({
        :controller => "repositories", 
        :action => "show", 
        :project_id => @project.to_param,
        :format => "xml",
        :id => @repo.to_param,
      }, "/#{@project.to_param}/#{@repo.to_param}.xml")
      assert_recognizes({
        :controller => "merge_requests", 
        :action => "index", 
        :format => "xml",
        :project_id => @project.to_param,
        :repository_id => @repo.to_param,
      }, "/#{@project.to_param}/#{@repo.to_param}/merge_requests.xml")
    
      assert_generates("/#{@project.to_param}/#{@repo.to_param}.xml", {
        :controller => "repositories", 
        :action => "show", 
        :project_id => @project.to_param,
        :id => @repo.to_param,
        :format => "xml",
      })
      assert_generates("/#{@project.to_param}/#{@repo.to_param}/merge_requests", {
        :controller => "merge_requests", 
        :action => "index", 
        :project_id => @project.to_param,
        :repository_id => @repo.to_param,
      })
    end

    should "recognizes routing like /projectname/repositories, with a non-html format" do
      assert_recognizes({
        :controller => "repositories",
        :action => "index", 
        :format => "xml",
        :project_id => @project.to_param
      }, "/#{@project.to_param}/repositories.xml")
    
      assert_generates("/#{@project.to_param}/repositories.xml", {
        :controller => "repositories", 
        :action => "index", 
        :project_id => @project.to_param,
        :format => "xml",
      })
    end
  end
  
  context "Routing, by users" do
    should "recognizes routing like /~username/repositories" do
      user = users(:johan)
      assert_recognizes({
        :controller => "repositories",
        :action => "index", 
        :user_id => user.to_param
      }, "/~#{user.to_param}/repositories")
    
      assert_generates("/~#{user.to_param}/repositories", {
        :controller => "repositories", 
        :action => "index", 
        :user_id => user.to_param,
      })
    end

    should "recognizes routing like /~username/repositories, with a non-html format" do
      user = users(:johan)
      assert_recognizes({
        :controller => "repositories",
        :action => "index", 
        :format => "xml",
        :user_id => user.to_param
      }, "/~#{user.to_param}/repositories.xml")
    
      assert_generates("/~#{user.to_param}/repositories.xml", {
        :controller => "repositories", 
        :action => "index", 
        :user_id => user.to_param,
        :format => "xml",
      })
    end
    
    should "recognize routing like /~user/reponame" do
      user = users(:johan)
      assert_recognizes({
        :controller => "repositories",
        :action => "show", 
        :user_id => user.to_param,
        :id => @repo.to_param,
      }, "/~#{user.to_param}/#{@repo.to_param}")
    
      assert_generates("/~#{user.to_param}/#{@repo.to_param}", {
        :controller => "repositories", 
        :action => "show", 
        :user_id => user.to_param,
        :id => @repo.to_param,
      })
    end
    
    should "recognize routing like /~user/reponame/action" do
      user = users(:johan)
      assert_recognizes({
        :controller => "repositories",
        :action => "edit", 
        :user_id => user.to_param,
        :id => @repo.to_param,
      }, "/~#{user.to_param}/#{@repo.to_param}/edit")
    
      assert_generates("/~#{user.to_param}/#{@repo.to_param}/edit", {
        :controller => "repositories", 
        :action => "edit", 
        :user_id => user.to_param,
        :id => @repo.to_param,
      })
    end
    
    should "recognize routing like /~user/projectname/reponame" do
      user = users(:johan)
      assert_recognizes({
        :controller => "repositories",
        :action => "show", 
        :project_id => @project.to_param,
        :user_id => user.to_param,
        :id => @repo.to_param,
      }, "/~#{user.to_param}/#{@project.to_param}/#{@repo.to_param}")
    
      assert_generates("/~#{user.to_param}/#{@project.to_param}/#{@repo.to_param}", {
        :controller => "repositories", 
        :action => "show", 
        :project_id => @project.to_param,
        :user_id => user.to_param,
        :id => @repo.to_param,
      })
    end
    
    should "recognize routing like /~user/projectname/reponame/action" do
      user = users(:johan)
      assert_recognizes({
        :controller => "repositories",
        :action => "clone", 
        :project_id => @project.to_param,
        :user_id => user.to_param,
        :id => @repo.to_param,
      }, "/~#{user.to_param}/#{@project.to_param}/#{@repo.to_param}/clone")
    
      assert_generates("/~#{user.to_param}/#{@project.to_param}/#{@repo.to_param}/clone", {
        :controller => "repositories", 
        :action => "clone", 
        :project_id => @project.to_param,
        :user_id => user.to_param,
        :id => @repo.to_param,
      })
    end
  end
  
  context "Routing, by teams" do
    should "recognizes routing like /+teamname/repositories" do
      team = groups(:team_thunderbird)
      assert_recognizes({
        :controller => "repositories",
        :action => "index", 
        :group_id => team.to_param
      }, "/+#{team.to_param}/repositories")
    
      assert_generates("/+#{team.to_param}/repositories", {
        :controller => "repositories", 
        :action => "index", 
        :group_id => team.to_param,
      })
    end
    
    should "recognizes routing like /+teamname/repo" do
      team = groups(:team_thunderbird)
      repo = team.repositories.first
      assert_recognizes({
        :controller => "repositories",
        :action => "show", 
        :group_id => team.to_param,
        :id => repo.to_param
      }, "/+#{team.to_param}/#{repo.to_param}")
    
      assert_generates("/+#{team.to_param}/#{repo.to_param}", {
        :controller => "repositories", 
        :action => "show", 
        :group_id => team.to_param,
        :id => repo.to_param
      })
    end

    should "recognizes routing like /+teamname/repo/action" do
      team = groups(:team_thunderbird)
      repo = team.repositories.first
      assert_recognizes({
        :controller => "repositories",
        :action => "clone", 
        :group_id => team.to_param,
        :id => repo.to_param
      }, "/+#{team.to_param}/#{repo.to_param}/clone")
    
      assert_generates("/+#{team.to_param}/#{repo.to_param}/clone", {
        :controller => "repositories", 
        :action => "clone", 
        :group_id => team.to_param,
        :id => repo.to_param
      })
    end

    should "recognizes routing like /+teamname/repositories, with a non-html format" do
      team = groups(:team_thunderbird)
      assert_recognizes({
        :controller => "repositories",
        :action => "index", 
        :format => "xml",
        :group_id => team.to_param
      }, "/+#{team.to_param}/repositories.xml")
      assert_generates("/+#{team.to_param}/repositories.xml", {
        :controller => "repositories", 
        :action => "index", 
        :group_id => team.to_param,
        :format => "xml",
      })
    end
  end

  context "#index" do
    setup do
      @project = projects(:johans)
    end
  
    should "gets all the projects repositories" do
      get :index, :project_id => @project.slug
      assert_response :success
      assert_equal @project.repositories, assigns(:repositories)
    end
    
    should 'render xml if requested' do
      get :index, :project_id => @project.slug, :format => 'xml'
      assert_response :success
    end
  end

  context "showing a user namespaced repo" do
    setup do
      @user = users(:johan)
      @project = projects(:johans)
    end
  
    should "GET users/johan/repositories/foo is successful" do
      repo = @user.repositories.first
      repo.stubs(:git).returns(stub_everything("git mock"))
      get :show, :user_id => @user.to_param, :project_id => repo.project.to_param,
        :id => repo.to_param
      assert_response :success
      assert_equal @user, assigns(:owner)
    end
    
    should "set the correct atom feed discovery url" do
      repo = @user.repositories.first
      repo.kind = Repository::KIND_USER_REPO
      repo.owner = @user
      repo.save!
      repo.stubs(:git).returns(stub_everything("git mock"))
      get :show, :user_id => @user.to_param, :project_id => repo.project.to_param,
        :id => repo.to_param
      assert_response :success
      atom_url = user_project_repository_path(@user, repo.project, repo, :format => :atom)
      assert_equal atom_url, assigns(:atom_auto_discovery_url)
    end
    
    should "find the correct owner for clone, if the project is owned by someone else" do
      clone_repo = @project.repositories.clones.first
      clone_repo.owner = users(:moe)
      clone_repo.save!
      clone_repo.stubs(:git).returns(stub_everything("git mock"))
      
      get :show, :user_id => users(:moe).to_param, 
        :project_id => clone_repo.project.to_param, :id => clone_repo.to_param
      assert_response :success
      assert_equal clone_repo, assigns(:repository)
      assert_equal users(:moe), assigns(:owner)
    end
    
    should "find the correct repository, even if the repo is named similar to another one in another project" do
      repo_clone = Repository.new_by_cloning(repositories(:moes), users(:johan).login)
      repo_clone.owner = users(:johan)
      repo_clone.user = users(:johan)
      repo_clone.name = "johansprojectrepos"
      repo_clone.save!
      
      get :show, :user_id => users(:johan).to_param, 
        :project_id => projects(:moes).to_param, :id => repo_clone.to_param
      assert_response :success
      assert_equal users(:johan), assigns(:owner)
      assert_equal repo_clone, assigns(:repository)
    end
    
    should "find the project repository" do
      get :show, :project_id => repositories(:johans).project.to_param, 
        :id => repositories(:johans).to_param
      assert_response :success
      assert_equal repositories(:johans).project, assigns(:owner)
      assert_equal repositories(:johans), assigns(:repository)
    end
  end

  context "showing a team namespaced repo" do
    setup do
      @group = groups(:team_thunderbird)
    end
  
    should "GET teams/foo/repositories/bar is successful" do
      repo = @group.repositories.first
      repo.stubs(:git).returns(stub_everything("git mock"))
      get :show, :project_id => repo.project.to_param,
        :group_id => @group.to_param, :id => repo.to_param
      assert_response :success
      assert_equal @group, assigns(:owner)
    end
  end

  def do_show_get(repos)
    get :show, :project_id => @project.slug, :id => repos.name
  end

  context "#show" do
    setup do
      @project = projects(:johans)
      @repo = @project.repositories.mainlines.first 
    end
  
    should "GET projects/1/repositories/1 is successful" do
      @repo.stubs(:git).returns(stub_everything("git mock"))
      do_show_get @repo
      assert_response :success
    end
  
    should "scopes GET :show to the project_id" do
      repo = repositories(:moes)
      repo.stubs(:git).returns(stub_everything("git mock"))
      do_show_get repo
      assert_response 404
    end
  
    should "issues a Refresh header if repo isn't ready yet" do
      @repo.stubs(:ready).returns(false)
      do_show_get @repo
      assert_response :success
      assert_not_nil @response.headers['Refresh']
    end
  end

  context "#show as XML" do
  
    setup do
      @project = projects(:johans)
    end
  
    should "GET projects/1/repositories/1.xml is successful" do
      repo = @project.repositories.mainlines.first
      repo.stubs(:has_commits?).returns(false)
      repo.stubs(:git).returns(stub_everything("git mock"))
      get :show, :project_id => @project.to_param, :id => repo.to_param, :format => "xml"
      assert_response :success
      assert_equal repo.to_xml, @response.body
    end
  end
  
  def do_clone_get()
    get :clone, :project_id => @project.slug, :id => @repository.name
  end

  context "#clone" do
    setup do
      login_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
    end
  
    should " require login" do
      session[:user_id] = nil
      do_clone_get
      assert_redirected_to(new_sessions_path)
    end
  
    should "GET projects/1/repositories/3/clone is successful" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name_in_project!).with(@repository.name, nil).returns(@repository)
      do_clone_get
      assert_equal nil, flash[:error]
      assert_response :success
      assert_equal @repository, assigns(:repository_to_clone)
      assert_instance_of Repository, assigns(:repository)
      assert_equal "johans-clone", assigns(:repository).name
    end
  
    should "redirects to new_account_key_path if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan
      do_clone_get
      assert_redirected_to(new_user_key_path(users(:johan)))
    end
  
    should "redirects with a flash if repos can't be cloned" do
      login_as :johan
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(false)
      @project.repositories.expects(:find_by_name_in_project!).with(@repository.name, nil).returns(@repository)
      do_clone_get
      assert_redirected_to(project_repository_path(@project, @repository))
      assert_match(/can't clone an empty/i, flash[:error])
    end
  end
  
  def do_create_clone_post(opts={})
    post(:create_clone, :project_id => @project.slug, :id => @repository.name,
      :repository => {:owner_type => "User"}.merge(opts))
  end

  context "#create_clone" do
    setup do
      login_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
    end
  
    should " require login" do
      session[:user_id] = nil
      do_create_clone_post
      assert_redirected_to(new_sessions_path)
    end
  
    should "post projects/1/repositories/3/create_clone is successful" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name_in_project!).with(@repository.name, nil).returns(@repository)
      do_create_clone_post(:name => "foo-clone")
      assert_response :redirect
    end
  
    should "post projects/1/repositories/3/create_clone is successful sets the owner to the user" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name_in_project!).with(@repository.name, nil).returns(@repository)
      do_create_clone_post(:name => "foo-clone", :owner_type => "User")
      assert_response :redirect
      assert_equal users(:johan), assigns(:repository).owner
      assert_equal Repository::KIND_USER_REPO, assigns(:repository).kind
    end
  
    should "post projects/1/repositories/3/create_clone is successful sets the owner to the group" do
      groups(:team_thunderbird).add_member(users(:johan), Role.admin)
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name_in_project!).with(@repository.name, nil).returns(@repository)
      do_create_clone_post(:name => "foo-clone", :owner_type => "Group", :owner_id => groups(:team_thunderbird).id)
      assert_response :redirect
      assert_equal groups(:team_thunderbird), assigns(:repository).owner
      assert_equal Repository::KIND_TEAM_REPO, assigns(:repository).kind
    end
  
    should "redirects to new_user_key_path if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan
      do_create_clone_post
      assert_redirected_to(new_user_key_path(users(:johan)))
    end
  
    should "redirects with a flash if repos can't be cloned" do
      login_as :johan
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(false)
      @project.repositories.expects(:find_by_name_in_project!).with(@repository.name, nil).returns(@repository)
      do_create_clone_post(:name => "foobar")
      assert_redirected_to(project_repository_path(@project, @repository))
      assert_match(/can't clone an empty/i, flash[:error])
    end
  end

  context "#create_clone as XML" do
  
    setup do
      authorize_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
      @request.env["HTTP_ACCEPT"] = "application/xml"
    end
  
    should " require login" do
      authorize_as(nil)
      do_create_clone_post(:name => "foo")
      assert_response 401
    end
  
    should "post projects/1/repositories/3/create_copy is successful" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name_in_project!).with(@repository.name, nil).returns(@repository)
      do_create_clone_post(:name => "foo-clone")
      assert_response 201
    end
  
    should "renders text if repos can't be cloned" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(false)
      @project.repositories.expects(:find_by_name_in_project!).with(@repository.name, nil).returns(@repository)
      do_create_clone_post(:name => "foobar")
      assert_response 422
      assert_match(/can't clone an empty/i, @response.body)
    end
  end
  
  def do_writable_by_get(options={})
    post(:writable_by, {:project_id => @project.slug, :id => @repository.name,
      :username => "johan"}.merge(options))
  end

  context "#writable_by" do
    setup do
      login_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
    end
  
    should " not require login" do
      session[:user_id] = nil
      do_writable_by_get :username => "johan"
      assert_response :success
    end
  
    should "get projects/1/repositories/3/writable_by?username=johan is true" do
      do_writable_by_get :username => "johan"
      assert_response :success
      assert_equal "true #{@repository.real_gitdir}", @response.body
    end
  
    should "get projects/1/repositories/2/writable_by?username=johan is false" do
      do_writable_by_get :username => "johan", :project_id => projects(:moes).slug, 
        :id => projects(:moes).repositories.first.name
      assert_response :success
      assert_equal "false nil", @response.body
    end
  
    should "get projects/1/repositories/2/writable_by?username=nonexistinguser is false" do
      do_writable_by_get :username => "nonexistinguser"
      assert_response :success
      assert_equal "false nil", @response.body
    end
  
    should "finds the repository in the whole project realm, if the (url) root is a project" do
      # in case someone changes a mainline to be owned by a group
      assert_equal @project, repositories(:johans2).project
      do_writable_by_get :id => repositories(:johans2).to_param
      assert_response :success
      assert_equal @project, assigns(:project)
      assert_equal repositories(:johans2), assigns(:repository)
    end
    
    should "scope to the correc project" do
      repo_clone = Repository.new_by_cloning(repositories(:moes), users(:johan).login)
      repo_clone.owner = users(:johan)
      repo_clone.user = users(:johan)
      repo_clone.name = "johansprojectrepos"
      repo_clone.save!
      
      do_writable_by_get({
        :user_id => users(:johan).to_param, 
        :project_id => projects(:moes).to_param, 
        :id => repo_clone.to_param,
      })
      assert_response :success
      assert_nil assigns(:project)
      assert_equal repo_clone.project, assigns(:containing_project)
      assert_equal repo_clone, assigns(:repository)
    end
    
    should "not require any particular subdomain (if Project belongs_to a site)" do
      project = projects(:johans)
      assert_not_nil project.site
      do_writable_by_get :project_id => project.to_param,
        :id => project.repositories.mainlines.first.to_param
      assert_response :success
    end
  end
  
  def do_delete(repos)
    delete :destroy, :project_id => @project.slug, :id => repos.name
  end

  context "#destroy" do
    setup do
      @project = projects(:johans)
    end
  
    should " require login" do
      session[:user_id] = nil
      do_delete(@project.repositories.mainlines.first)
      assert_redirected_to(new_sessions_path)
    end
  
    should "can only be deleted by the owner" do
      login_as :johan
      @project.repositories.last.update_attribute(:user_id, users(:moe).id)
      do_delete(@project.repositories.last)
      assert_redirected_to(project_path(@project))
      assert_equal "You're not the owner of this repository", flash[:error]
    end
  
    should "the owner can delete his own repos" do
      login_as :johan
      repo = repositories(:johans2)
      repo.user = users(:johan)
      repo.save!
      delete :destroy, :project_id => repo.project.to_param,
        :group_id => repo.owner.to_param, :id => repo.to_param
      assert_equal nil, flash[:error]
      assert_equal "The repository was deleted", flash[:notice]
      assert_redirected_to(group_path(repo.owner))
    end
  
    should "destroying a project creates an event in the project" do
      login_as :johan
      repo = repositories(:johans2)
      repo.user = users(:johan)
      repo.save!
      assert_difference("repo.project.events.count") do
        delete :destroy, :project_id => repo.project.to_param,
          :group_id => repo.owner.to_param, :id => repo.to_param
        assert_response :redirect
      end
    end
    
    should "work for user/group clones" do
      repo = repositories(:johans2)
      repo.user = users(:mike)
      repo.save!
      login_as :mike
      get :confirm_delete, :group_id => repo.owner.to_param, 
        :project_id => repo.project.to_param, :id => repo.to_param
      assert_response :success
      assert_template "confirm_delete"
    end
  end

  context "new / create" do
    setup do
      @project = projects(:johans)
      @user = users(:johan)
      @group = groups(:team_thunderbird)
      @group.add_member(@user, Role.admin)
      login_as :johan
    end
  
    should " require login" do
      login_as nil
      get :new, :project_id => @project.to_param
      assert_redirected_to(new_sessions_path)
    end
  
    should "require adminship" do
      login_as :moe
      get :new, :project_id => @project.to_param
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_redirected_to(project_path(@project))
    
      post :create, :project_id => @project.to_param, :repository => {}
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_redirected_to(project_path(@project))
    end
  
    should "only be allowed to add new repositories to Project" do
      get :new, :project_id => @project.to_param, :group_id => @group.to_param
      assert_match(/can only add new repositories directly to a project/, flash[:error])
      assert_redirected_to(group_path(@group))
    
      get :new, :project_id => @project.to_param, :user_id => @user.to_param
      assert_match(/can only add new repositories directly to a project/, flash[:error])
      assert_redirected_to(user_path(@user))
    
      post :create, :project_id => @project.to_param, :group_id => @group.to_param, :repository => {}
      assert_match(/can only add new repositories directly to a project/, flash[:error])
      assert_redirected_to(group_path(@group))
    
      post :create, :project_id => @project.to_param, :user_id => @user.to_param, :repository => {}
      assert_match(/can only add new repositories directly to a project/, flash[:error])
      assert_redirected_to(user_path(@user))
    end
  
    # See the above example ("should only be allowed to add new repositories to Project")
    # for why this is commented out
    # 
    # it "should GET new successfully, and set the owner to a user" do
    #   get :new, :user_id => @user.to_param
    #   assert_response :success
    #   assert_equal @user, #   assigns(:owner)
    # end
    # 
    # it "should GET new successfully, and set the owner to a group" do
    #   get :new, :group_id => @group.to_param
    #   assert_response :success
    #   assert_equal @group, #   assigns(:owner)
    # end
    # 
    # it "creates a new repository belonging to a user" do
    #   proc {
    #     post :create, :user_id => @user.to_param, :repository => {:name => "my-new-repo"}
    #   }.should change(Repository, :count)
    #   assert_equal @user, #   assigns(:repository).owner
    #  assert_response :redirect
    #  assert_redirected_to(user_repository_path(@user, assigns(:repository)))
    # end
    # 
    # it "creates a new repository belonging to a group" do
    #   proc {
    #     post :create, :group_id => @group.to_param, :repository => {:name => "my-new-repo"}
    #   }.should change(Repository, :count)
    #   assert_equal @group, #   assigns(:repository).owner
    #   assert_response :redirect
    #   assert_redirected_to(group_repository_path(@group, assigns(:repository)))
    # end
  
    should " GET new successfully, and set the owner to a project" do
      get :new, :project_id => @project.to_param
      assert_response :success
      assert_equal @project, assigns(:owner)
    end
  
    should "creates a new repository belonging to a Project" do
      assert_difference("Repository.count") do
        post :create, :project_id => @project.to_param, :repository => {:name => "my-new-repo"}
      end
      assert_equal @project.owner, assigns(:repository).owner
      assert_equal Repository::KIND_PROJECT_REPO, assigns(:repository).kind
      assert_response :redirect
      assert_redirected_to(project_repository_path(@project, assigns(:repository)))
    end
  end

  context "edit / update" do
    setup do
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
      login_as :johan
      groups(:team_thunderbird).add_member(users(:johan), Role.admin)
    end
  
    should "requires login" do
      login_as nil
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_redirected_to(new_sessions_path)
    
      put :update, :project_id => @project.to_param, :id => @repository.to_param
      assert_redirected_to(new_sessions_path)
    end
    
    should "requires adminship on the project if owner is a project" do
      login_as :moe
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_redirected_to(project_path(@project))
    end
    
    should "requires adminship on the user if owner is a user" do
      login_as :moe
      @repository.owner = users(:moe)
      @repository.kind = Repository::KIND_USER_REPO
      @repository.save!
      get :edit, :project_id => @repository.project.to_param,
        :user_id => users(:moe).to_param, :id => @repository.to_param
      assert_response :success
    end
    
    should "requires adminship on the group, if the owner is a group" do
      login_as :mike
      @repository.owner = groups(:team_thunderbird)
      @repository.kind = Repository::KIND_TEAM_REPO
      @repository.save!
      get :edit, :project_id => @repository.project.to_param, 
        :group_id => groups(:team_thunderbird).to_param, :id => @repository.to_param
      assert_response :success
    end
  
    should "GETs edit/n successfully" do
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response :success
      assert_equal @repository, assigns(:repository)
    end
  
    should "PUT update successfully and creates an event when changing the description" do
      assert_incremented_by(@repository.events, :size, 1) do
        put :update, :project_id => @project.to_param, :id => @repository.to_param,
          :repository => {:description => "blablabla"}
        @repository.events.reload
      end
      assert_redirected_to(project_repository_path(@project, @repository))
      assert_equal "blablabla", @repository.reload.description
    end
    
    should 'not create an event on update if the description is not changed' do
      assert_no_difference("@repository.events.size") do
        put :update, :project_id => @project.to_param, :id => @repository.to_param,
          :repository => {:description => @repository.description}
        @repository.events.reload
      end
    end
  
    should "gets a list of the users' groups on edit" do
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response :success
      assert_equal users(:johan).groups, assigns(:groups)
    end
  
    should "gets a list of the users' groups on update" do
      put :update, :project_id => @project.to_param, :id => @repository.to_param, 
            :repository => {:description => "foo"}
      assert_equal users(:johan).groups, assigns(:groups)
    end
  
    should "changes the owner" do
      group = groups(:team_thunderbird)
      put :update, :project_id => @project.to_param, :id => @repository.to_param, :repository => {
        :owner_id => group.id,
      }
      assert_redirected_to(project_repository_path(@repository.project, @repository))
      assert_equal group, @repository.reload.owner
    end
  
    should "changes the owner, only if the original owner was a user" do
      group = groups(:team_thunderbird)
      @repository.owner = group
      @repository.kind = Repository::KIND_TEAM_REPO
      @repository.save!
      new_group = Group.create!(:name => "temp")
      new_group.add_member(users(:johan), Role.admin)
    
      put :update, :project_id => @repository.project.to_param, 
        :group_id => group.to_param, :id => @repository.to_param, :repository => {
          :owner_id => new_group.id
        }
      assert_response :redirect
      assert_redirected_to(group_repository_path(group, @repository))
      assert_equal group, @repository.reload.owner
    end
  end

  context "with committer (not owner) logged in" do
    should "GET projects/1/repositories/3 and have merge request link" do
      login_as :mike
      project = projects(:johans)
      repository = project.repositories.mainlines.first
      repository.committerships.create!(:committer => users(:mike))
      
      Project.expects(:find_by_slug!).with(project.slug).returns(project)
      repository.stubs(:has_commits?).returns(true)
    
      get :show, :project_id => project.to_param, :id => repository.to_param
      assert_equal nil, flash[:error]
      assert_select("#sidebar ul.links li a[href=?]", 
        new_project_repository_merge_request_path(project, repository),
        :content => "Request merge")
    end
  end
end
