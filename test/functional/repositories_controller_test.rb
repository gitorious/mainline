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

class RepositoriesControllerTest < ActionController::TestCase
  def setup
    @settings = Gitorious::Configuration.prepend("enable_private_repositories" => false)
    setup_ssl_from_config
    @project = projects(:johans)
    @repo = repositories(:johans)
    @grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(@grit)
  end

  teardown do
    Gitorious::Configuration.prune(@settings)
  end

  should_render_in_site_specific_context :except => [:writable_by, :repository_config]

  context "#index" do
    setup do
      @project = projects(:johans)
    end

    should "gets all the projects repositories" do
      get :index, :project_id => @project.slug
      assert_response :success
      assert_equal @project.repositories, assigns(:repositories)
    end

    should "render xml if requested" do
      get :index, :project_id => @project.slug, :format => "xml"
      assert_response :success
    end

    context "paginating repositories" do
      setup { @params = { :project_id => @project.slug } }
      should_scope_pagination_to(:index, Repository)
    end
  end

  context "Searching" do
    setup do
      @project = projects(:johans)
    end

    should "render repositories matching a search term" do
      get :index, :project_id => @project.to_param, :filter => "clone", :format => "json"
      assert_response :success
      assert_equal([repositories(:johans2)], assigns(:repositories))
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

      get :show, {
        :user_id => @user.to_param,
        :project_id => repo.project.to_param,
        :id => repo.to_param
      }

      assert_response :success
      atom_url = project_repository_path(repo.project, repo, :format => :atom)
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
      cmd = CloneRepositoryCommand.new(MessageHub.new, repositories(:moes), users(:johan))
      repo_clone = cmd.execute(cmd.build(CloneRepositoryInput.new(:name => "johansprojectrepos")))

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

    context "paginating repository events" do
      setup do
        @params = {
          :project_id => repositories(:johans).project.to_param,
          :id => repositories(:johans).to_param
        }
      end

      should_scope_pagination_to(:show, Event)
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

    should "issues a Refresh header if repo is not ready yet" do
      @repo.stubs(:ready).returns(false)
      do_show_get @repo
      assert_response :success
      assert_not_nil @response.headers["Refresh"]
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

  context "#clone" do
    setup do
      login_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
    end

    should "require login" do
      session[:user_id] = nil
      do_clone_get
      assert_redirected_to(new_sessions_path)
    end

    should "GET projects/1/repositories/3/clone is successful" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      do_clone_get

      assert_equal nil, flash[:error]
      assert_response :success
      assert_equal @repository, assigns(:repository_to_clone)
      assert_instance_of Repository, assigns(:repository)
      assert_equal "johans-johansprojectrepos", assigns(:repository).name
    end

    should "redirects to new_account_key_path if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan
      do_clone_get
      assert_redirected_to(new_user_key_path(users(:johan)))
    end

    should "redirects with a flash if repos cannot be cloned" do
      login_as :johan
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(false)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      do_clone_get

      assert_redirected_to(project_repository_path(@project, @repository))
      assert_match(/cannot clone an empty/i, flash[:error])
    end
  end

  context "#create_clone" do
    setup do
      login_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
    end

    should "require login" do
      session[:user_id] = nil
      do_create_clone_post
      assert_redirected_to(new_sessions_path)
    end

    should "post projects/1/repositories/3/create_clone is successful" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)

      do_create_clone_post(:name => "foo-clone")

      assert_response :redirect
    end

    should "post projects/1/repositories/3/create_clone is successful sets the owner to the user" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      do_create_clone_post(:name => "foo-clone", :owner_type => "User")

      assert_response :redirect
      assert_equal users(:johan), Repository.last.owner
      assert_equal Repository::KIND_USER_REPO, Repository.last.kind
    end

    should "post projects/1/repositories/3/create_clone is successful sets the owner to the group" do
      groups(:team_thunderbird).add_member(users(:johan), Role.admin)
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      do_create_clone_post(:name => "foo-clone", :owner_type => "Group", :owner_id => groups(:team_thunderbird).id)

      assert_response :redirect
      assert_equal groups(:team_thunderbird), Repository.last.owner
      assert_equal Repository::KIND_TEAM_REPO, Repository.last.kind
    end

    should "redirects to new_user_key_path if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan

      do_create_clone_post

      assert_redirected_to(new_user_key_path(users(:johan)))
    end

    should "redirects with a flash if repos cannot be cloned" do
      login_as :johan
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(false)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      do_create_clone_post(:name => "foobar")

      assert_redirected_to(project_repository_path(@project, @repository))
      assert_match(/cannot clone an empty/i, flash[:error])
    end
  end

  context "#create_clone as XML" do

    setup do
      authorize_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
      @request.env["HTTP_ACCEPT"] = "application/xml"
    end

    should "require login" do
      authorize_as(nil)
      do_create_clone_post(:name => "foo")
      assert_response 401
    end

    should "post projects/1/repositories/3/create_copy is successful" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      do_create_clone_post(:name => "foo-clone")

      assert_response 201
    end

    should "renders text if repos cannot be cloned" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(false)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
      do_create_clone_post(:name => "foobar")
      assert_response 422
      assert_match(/cannot clone an empty/i, @response.body)
    end
  end

  context "#writable_by" do
    setup do
      login_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
    end

    should "not require login" do
      session[:user_id] = nil
      do_writable_by_get :username => "johan"
      assert_response :success
    end

    should "get projects/1/repositories/3/writable_by?username=johan is true" do
      do_writable_by_get :username => "johan"
      assert_response :success
      assert_equal "true", @response.body
    end

    should "get projects/1/repositories/2/writable_by?username=johan is false" do
      do_writable_by_get :username => "johan", :project_id => projects(:moes).slug,
      :id => projects(:moes).repositories.first.name
      assert_response :success
      assert_equal "false", @response.body
    end

    should "get projects/1/repositories/2/writable_by?username=nonexistinguser is false" do
      do_writable_by_get :username => "nonexistinguser"
      assert_response :success
      assert_equal "false", @response.body
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
      cmd = CloneRepositoryCommand.new(MessageHub.new, repositories(:moes), users(:johan))
      repo_clone = cmd.execute(cmd.build(CloneRepositoryInput.new(:name => "johansprojectrepos")))

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

    should "not identify a non-merge request git path as a merge request" do
      do_writable_by_get({
          :git_path => "refs/heads/master"})
      assert_response :success
      assert_equal "true", @response.body
    end

    should "identify that a merge request is being pushed to" do
      @merge_request = merge_requests(:mikes_to_johans)
      assert !can_push?(@merge_request.user, @merge_request.target_repository)
      do_writable_by_get({
          :username => @merge_request.user.to_param,
          :project_id => @merge_request.target_repository.project.to_param,
          :id => @merge_request.target_repository.to_param,
          :git_path => "refs/merge-requests/#{@merge_request.to_param}"})
      assert_response :success
      assert_equal "true", @response.body
    end

    should "not allow other users than the owner of a merge request push to a merge request" do
      @merge_request = merge_requests(:mikes_to_johans)
      do_writable_by_get({
          :username => "johan",
          :project_id => @merge_request.target_repository.project.to_param,
          :id => @merge_request.target_repository.to_param,
          :git_path => "refs/merge-requests/#{@merge_request.to_param}"})
      assert_response :success
      assert_equal "false", @response.body
    end

    should "not allow pushes to non-existing merge requests" do
      @merge_request = merge_requests(:mikes_to_johans)
      do_writable_by_get({
          :username => "johan",
          :project_id => @merge_request.target_repository.project.to_param,
          :id => @merge_request.target_repository.to_param,
          :git_path => "refs/merge-requests/42"})
      assert_response :success
      assert_equal "false", @response.body
    end


    should "allow pushing to wiki repositories" do
      project = projects(:johans)
      wiki = project.wiki_repository
      user = users(:johan)
      do_writable_by_get(:id => wiki.to_param)
      assert_response :success
    end
  end

  context "#config" do
    setup do
      login_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
    end

    should "not require login" do
      session[:user_id] = nil
      do_config_get
      assert_response :success
    end

    should "get projects/1/repositories/3/config is true" do
      do_config_get
      assert_response :success
      exp = "real_path:#{@repository.real_gitdir}\nforce_pushing_denied:false"
      assert_equal exp, @response.body
    end

    should "expose the wiki repository" do
      wiki = @project.wiki_repository
      assert_not_nil wiki
      do_config_get(:id => wiki.to_param)
      expected = "real_path:#{wiki.real_gitdir}\nforce_pushing_denied:false"
      assert_equal expected, @response.body
    end

    should "not use a session cookie" do
      do_config_get

      assert_nil @response.headers["Set-Cookie"]
    end

    should "send cache friendly headers" do
      do_config_get

      assert_equal "public, max-age=600", @response.headers["Cache-Control"]
    end
  end

  context "#destroy" do
    setup do
      @project = projects(:johans)
      @repo = @project.repositories.first
      assert admin?(users(:johan), @repo)
      login_as :johan
    end

    should "require login" do
      session[:user_id] = nil
      do_delete(@repo)
      assert_redirected_to(new_sessions_path)
    end

    should "can only be deleted by the admins" do
      login_as :mike
      assert !admin?(users(:mike), @repo)
      do_delete(@repo)
      assert_redirected_to([@project, @repo])
      assert_match(/only repository admins are allowed/i, flash[:error])
    end

    should "the owner can delete his own repos" do
      repo = repositories(:johans2)
      repo.user = users(:johan)
      repo.save!
      repo.committerships.create_with_permissions!({
          :committer => users(:johan)
        }, (Committership::CAN_ADMIN | Committership::CAN_COMMIT))
      assert admin?(users(:johan), repo.reload)
      delete :destroy, :project_id => repo.project.to_param,
      :group_id => repo.owner.to_param, :id => repo.to_param
      assert_equal nil, flash[:error]
      assert_equal "The repository was deleted", flash[:notice]
      assert_redirected_to(group_path(repo.owner))
    end

    should "destroying a project creates an event in the project" do
      assert_difference("@project.events.count") do
        do_delete(@repo)
        assert_response :redirect
        assert_nil flash[:error]
      end
    end

    should "work for user/group clones" do
      repo = repositories(:johans2)
      repo.user = users(:mike)
      repo.committerships.create_with_permissions!({
          :committer => users(:mike)
        }, (Committership::CAN_ADMIN | Committership::CAN_COMMIT))
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

    should "require login" do
      logout
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

    should "GET new successfully, and set the owner to a project" do
      get :new, :project_id => @project.to_param

      assert_response :success
      assert_equal @project, assigns(:owner)
    end

    should "creates a new repository belonging to a Project" do
      assert_difference("Repository.count") do
        post :create, :project_id => @project.to_param, :repository => {:name => "my-new-repo"}
      end
      repo = Repository.find_by_name("my-new-repo")
      assert_equal @project.owner, repo.owner
      assert_equal Repository::KIND_PROJECT_REPO, repo.kind
      assert_response :redirect
      assert_redirected_to(project_repository_path(@project, repo))
    end

    should "respect the creator's choice of merge requests or not" do
      post :create, :project_id => @project.to_param, :repository => {
        :name => "mine"
      }
      assert_not_nil repo = Repository.find_by_name("mine")
      assert repo.merge_requests_enabled?
      post :create, :project_id => @project.to_param, :repository => {
        :name => "mine2",
        :merge_requests_enabled => "0"
      }
      assert_not_nil repo = Repository.find_by_name("mine2")
      assert !repo.merge_requests_enabled?
    end
  end

  context "edit / update" do
    setup do
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
      login_as :johan
    end

    should "requires login" do
      logout
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_redirected_to(new_sessions_path)

      put :update, :project_id => @project.to_param, :id => @repository.to_param
      assert_redirected_to(new_sessions_path)
    end

    should "requires adminship on the project if owner is a project" do
      login_as :moe
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_response :redirect
    end

    should "requires adminship on the user if owner is a user" do
      login_as :moe
      @repository.owner = users(:moe)
      @repository.kind = Repository::KIND_USER_REPO
      @repository.committerships.create_with_permissions!({
          :committer => users(:moe)
        }, Committership::CAN_ADMIN)
      @repository.save!

      get :edit, {
        :project_id => @project.to_param,
        :user_id => users(:moe).to_param,
        :id => @repository.to_param
      }

      assert_response :success
    end

    should "requires adminship on the repo" do
      login_as :mike
      @repository.committerships.create_with_permissions!({
          :committer => groups(:team_thunderbird)
        }, Committership::CAN_ADMIN)
      @repository.kind = Repository::KIND_TEAM_REPO
      @repository.owner = groups(:team_thunderbird)
      @repository.save!
      assert admin?(users(:mike), @repository)
      get :edit, :project_id => @repository.project.to_param,
      :group_id => groups(:team_thunderbird).to_param, :id => @repository.to_param
      assert_response :success
    end

    should "GETs edit/n successfully" do
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response :success
      assert_equal @repository, assigns(:repository)
      assert_equal @grit.heads, assigns(:heads)
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

    should "be able to remove the repository description" do
      @repository.update_attribute(:description, "blabla bla")
      put :update, :project_id => @project.to_param, :id => @repository.to_param,
      :repository => {:description => ""}
      assert @repository.reload.description.blank?,
      "descr: #{@repository.description.inspect}"
    end

    should "update the repository name and create an event if a new name is provided" do
      description = @repository.description
      assert_incremented_by(@repository.events, :size, 1) do
        put :update, :project_id => @project.to_param, :id => @repository.to_param,
        :repository => {:name => "new_name"}
        @repository.events.reload
        @repository.reload
        assert_redirected_to project_repository_path(@project, @repository)
      end
      assert_equal "new_name", @repository.name
      assert_equal description, @repository.description
    end


    should "not create an event on update if the description is not changed" do
      assert_no_difference("@repository.events.size") do
        put :update, :project_id => @project.to_param, :id => @repository.to_param,
        :repository => {:description => @repository.description}
        @repository.events.reload
      end
    end

    should "gets a list of the users' groups on edit" do
      groups(:team_thunderbird).add_member(users(:johan), Role.admin)
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response :success
      assert_equal users(:johan).groups, assigns(:groups)
    end

    should "gets a list of the users' groups on update" do
      groups(:team_thunderbird).add_member(users(:johan), Role.admin)
      put :update, :project_id => @project.to_param, :id => @repository.to_param,
      :repository => {:description => "foo"}
      assert_equal users(:johan).groups, assigns(:groups)
    end

    should "changes the owner" do
      group = groups(:team_thunderbird)
      group.add_member(users(:johan), Role.admin)
      put :update, :project_id => @project.to_param, :id => @repository.to_param,
      :repository => { :owner_id => group.id}
      assert_redirected_to(project_repository_path(@repository.project, @repository))
      assert_equal group, @repository.reload.owner
    end

    should "changes the owner, only if the original owner was a user" do
      group = groups(:team_thunderbird)
      group.add_member(users(:johan), Role.admin)
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
      assert_redirected_to(project_repository_path(@project, @repository))
      assert_equal group, @repository.reload.owner
    end

    should "be able to deny force pushing" do
      @repository.update_attribute(:deny_force_pushing, false)
      put :update, :project_id => @repository.project.to_param, :id => @repository.to_param,
      :repository => { :deny_force_pushing => true }
      assert_response :redirect
      assert @repository.reload.deny_force_pushing?
    end

    should "be able to disable merge requests" do
      @repository.update_attribute(:merge_requests_enabled, true)
      put :update, :project_id => @repository.project.to_param, :id => @repository.to_param,
      :repository => {}
      assert_response :redirect
      assert !@repository.reload.merge_requests_enabled?
      put :update, :project_id => @repository.project.to_param, :id => @repository.to_param,
      :repository => {:merge_requests_enabled => 1}
      assert_response :redirect
      assert @repository.reload.merge_requests_enabled?
    end

    should "be able to turn off notify_committers_on_new_merge_request" do
      @repository.update_attribute(:notify_committers_on_new_merge_request, true)
      put :update, :project_id => @repository.project.to_param, :id => @repository.to_param,
      :repository => { :notify_committers_on_new_merge_request => false }
      assert_response :redirect
      assert !@repository.reload.notify_committers_on_new_merge_request?
    end

    context "Changing the HEAD" do
      should "update the HEAD if it is changed" do
        the_head = @grit.get_head("test/master")
        @grit.expects(:update_head).with(the_head).returns(true)
        put :update, :project_id => @project.to_param, :id => @repository.to_param,
        :repository => { :head => the_head.name }
        assert_equal @grit.heads, assigns(:heads)
      end
    end
  end

  context "with committer (not owner) logged in" do
    should "GET projects/1/repositories/3 and have merge request link" do
      login_as :mike
      project = projects(:johans)
      repository = project.repositories.clones.first
      committership = repository.committerships.new
      committership.committer = users(:mike)
       committership.permissions = Committership::CAN_REVIEW | Committership::CAN_COMMIT
       committership.save!

       Project.expects(:find_by_slug!).with(project.slug).returns(project)
       repository.stubs(:has_commits?).returns(true)

       get :show, :project_id => project.to_param, :id => repository.to_param
       assert_equal nil, flash[:error]
       assert_select("#sidebar ul.links li a[href=?]",
         new_project_repository_merge_request_path(project, repository),
         :content => "Request merge")
     end
   end

   context "search clones" do
     setup do
       @repo = repositories(:johans)
       @clone_repo = repositories(:johans2)
     end

     should "return a list of clones matching the query" do
       get :search_clones, :project_id => @repo.project.to_param, :id => @repo.to_param,
         :filter => "projectrepos", :format => "json"
       assert_response :success
       assert assigns(:repositories).include?(@clone_repo)
     end
   end

   should "not display git:// link when disabling the git daemon" do
     Gitorious.stubs(:git_daemon).returns(nil)
     project = projects(:johans)
     repository = project.repositories.mainlines.first
     repository.update_attribute(:ready, true)

    get :show, :project_id => project.to_param, :id => repository.to_param

    assert_no_match(/git:\/\//, @response.body)
  end

  context "With private projects" do
    setup do
      enable_private_repositories
      @group = groups(:team_thunderbird)
      @repository = @project.repositories.first
      Repository.any_instance.stubs(:has_commits?).returns(true)
    end

    should "disallow unauthorized users to get project repositories" do
      get :index, :project_id => @project.to_param
      assert_response 403
    end

    should "disallow unauthorized users to get group repositories" do
      get :index, :group_id => @group.to_param, :project_id => @project.to_param
      assert_response 403
    end

    should "disallow unauthorized users to get user repositories" do
      get :index, :user_id => users(:johan).to_param, :project_id => @project.to_param
      assert_response 403
    end

    should "allow authorize users to get project repositories" do
      login_as :johan
      get :index, :project_id => @project.to_param
      assert_response 200
    end

    should "allow authorize users to get group repositories" do
      login_as :johan
      get :index, :group_id => @group.to_param, :project_id => @project.to_param
      assert_response 200
    end

    should "allow authorize users to get user repositories" do
      login_as :johan
      get :index, :user_id => users(:johan).to_param, :project_id => @project.to_param
      assert_response 200
    end

    should "disallow unauthorized users to show repository" do
      get :show, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized users to get show repository" do
      login_as :johan
      get :show, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "disallow unauthorized users to get new" do
      login_as :mike
      get :new, :project_id => @project.to_param
      assert_response 403
    end

    should "allow authorized users to get new" do
      login_as :johan
      get :new, :project_id => @project.to_param
      assert_response 200
    end

    should "disallow unauthorized users to create repository" do
      login_as :mike
      post :create, :project_id => @project.to_param, :repository => {}
      assert_response 403
    end

    should "allow authorized users to create repository" do
      login_as :johan
      post :create, :project_id => @project.to_param, :repository => {}
      assert_response 200
    end

    should "disallow unauthenticated users to clone repo" do
      login_as :mike
      do_clone_get
      assert_response 403
    end

    should "allow authenticated users to clone repo" do
      login_as :johan
      do_clone_get
      assert_response 200
    end

    should "disallow unauthorized users to create clones" do
      login_as :mike
      do_create_clone_post(:name => "foo-clone")
      assert_response 403
    end

    should "allow authorized users to create clones" do
      login_as :johan
      do_create_clone_post(:name => "foo-clone")
      assert_response 302
    end

    should "disallow unauthorized user to edit repository" do
      login_as :mike
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized user to edit repository" do
      login_as :johan
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "disallow unauthorized users to search clones" do
      get :search_clones, :project_id => @project.to_param, :id => @repository.to_param,
        :filter => "projectrepos", :format => "json"
      assert_response 403
    end

    should "allow authorized users to search clones" do
      login_as :johan
      get :search_clones, :project_id => @project.to_param, :id => @repository.to_param,
        :filter => "projectrepos", :format => "json"
      assert_response 200
    end

    should "disallow unauthorized user to update repository" do
      login_as :mike
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized user to update repository" do
      login_as :johan
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "not disallow writable_by? action" do
      do_writable_by_get :username => "mike"
      assert_response :success
      assert_equal "false", @response.body
    end

    should "allow owner to write to repo" do
      do_writable_by_get :username => "johan"
      assert_response :success
      assert_equal "true", @response.body
    end

    should "disallow unauthorized user to access repository configuration" do
      do_config_get(:username => "mike")
      assert_response 403
    end

    should "disallow anonymous user to access repository configuration" do
      do_config_get
      assert_response 403
    end

    should "allow authorized user to access repository configuration" do
      do_config_get(:username => "johan")
      assert_response 200
    end

    should "disallow unauthorized user to confirm deletion" do
      login_as :mike
      get :confirm_delete, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized user to confirm deletion" do
      login_as :johan
      get :confirm_delete, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "disallow unauthorized user to destroy repository" do
      login_as :mike
      do_delete @repository
      assert_response 403
    end

    should "allow authorized user to destroy repository" do
      login_as :johan
      do_delete @repository
      assert_response 302
    end
  end

  context "With private repositories" do
    setup do
      enable_private_repositories(@repo)
      @group = groups(:team_thunderbird)
      @repository = @project.repositories.first
      Repository.any_instance.stubs(:has_commits?).returns(true)
    end

    teardown do
      user = users(:mike)
      user.is_admin = false
      user.save
    end

    should "exclude private repositories in project" do
      get :index, :project_id => @project.to_param
      assert_equal 1, assigns(:repositories).length
    end

    should "exclude filtered private repositories in project" do
      get :index, :project_id => @project.to_param, :filter => "o", :format => "json"
      assert_equal 1, assigns(:repositories).length
    end

    should "exclude private repositories in group" do
      Repository.all.each { |r| r.make_private }
      get :index, :group_id => @group.to_param, :project_id => @project.to_param
      assert_equal 0, assigns(:repositories).length
    end

    should "exclude private repositories in user" do
      get :index, :user_id => users(:johan).to_param, :project_id => @project.to_param
      assert_equal 1, assigns(:repositories).length
    end

    should "include authorized private repositories in project" do
      login_as :johan
      get :index, :project_id => @project.to_param
      assert_equal 2, assigns(:repositories).length
    end

    should "include authorized private repositories in group" do
      login_as :johan
      get :index, :group_id => @group.to_param, :project_id => @project.to_param
      assert_equal 1, assigns(:repositories).length
    end

    should "include authorized private repositories in user" do
      login_as :johan
      get :index, :user_id => users(:johan).to_param, :project_id => @project.to_param
      assert_equal 2, assigns(:repositories).length
    end

    should "disallow unauthorized users to show repository" do
      get :show, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized users to get show repository" do
      login_as :johan
      get :show, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "allow site admin to get show repository" do
      user = users(:mike)
      user.is_admin = true
      user.save
      login_as :mike
      get :show, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "disallow unauthenticated users to clone repo" do
      login_as :mike
      do_clone_get
      assert_response 403
    end

    should "allow authenticated users to clone repo" do
      login_as :johan
      do_clone_get
      assert_response 200
    end

    should "disallow unauthorized users to create clones" do
      login_as :mike
      do_create_clone_post(:name => "foo-clone")
      assert_response 403
    end

    should "allow authorized users to create clones" do
      login_as :johan
      do_create_clone_post(:name => "foo-clone")
      assert_response 302
    end

    should "disallow unauthorized user to edit repository" do
      login_as :mike
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized user to edit repository" do
      login_as :johan
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "disallow unauthorized users to search clones" do
      get :search_clones, :project_id => @project.to_param, :id => @repository.to_param,
        :filter => "projectrepos", :format => "json"
      assert_response 403
    end

    should "exclude private repositories when searching clones" do
      @repository.make_public
      @repository.clones.each(&:make_private)
      get :search_clones, :project_id => @project.to_param, :id => @repository.to_param,
        :filter => "projectrepos", :format => "json"
      assert_equal 0, assigns(:repositories).length
    end

    should "allow authorized users to search clones" do
      login_as :johan
      get :search_clones, :project_id => @project.to_param, :id => @repository.to_param,
        :filter => "projectrepos", :format => "json"
      assert_response 200
    end

    should "disallow unauthorized user to update repository" do
      login_as :mike
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized user to update repository" do
      login_as :johan
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "not disallow writable_by? action" do
      do_writable_by_get :username => "mike"
      assert_response :success
      assert_equal "false", @response.body
    end

    should "allow owner to write to repo" do
      do_writable_by_get :username => "johan"
      assert_response :success
      assert_equal "true", @response.body
    end

    should "disallow unauthorized user to access repository configuration" do
      do_config_get(:username => "mike")
      assert_response 403
    end

    should "disallow anonymous user to access repository configuration" do
      do_config_get
      assert_response 403
    end

    should "allow authorized user to access repository configuration" do
      do_config_get(:username => "johan")
      assert_response 200
    end

    should "disallow unauthorized user to confirm deletion" do
      login_as :mike
      get :confirm_delete, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized user to confirm deletion" do
      login_as :johan
      get :confirm_delete, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "disallow unauthorized user to destroy repository" do
      login_as :mike
      do_delete @repository
      assert_response 403
    end

    should "allow authorized user to destroy repository" do
      login_as :johan
      do_delete @repository
      assert_response 302
    end

    should "create private repository" do
      login_as :johan

      assert_difference "Repository.count" do
        post(:create,
          :project_id => @project.to_param,
          :repository => { :name => "my-new-repo" },
          :private => "1")

        assert_response :redirect
        assert Repository.last.private?
      end
    end

    context "cloning" do
      setup do
        login_as :moe
        Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
        @repository.stubs(:has_commits?).returns(true)
        @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
      end

      should "clone private repository" do
        @repository.make_private
        @repository.add_member(users(:moe))
        do_create_clone_post(:name => "foo-clone")
        assert Repository.last.private?
      end

      should "clone public repository" do
        do_create_clone_post(:name => "foo-clone")
        assert !Repository.last.private?
      end

      should "add parent members to new repository" do
        @repository.make_private
        @repository.add_member(users(:moe))
        @repository.add_member(users(:old_timer))
        do_create_clone_post(:name => "foo-clone")
        assert can_read?(users(:old_timer), Repository.last)
        assert can_read?(users(:moe), Repository.last)
        assert can_read?(@repository.owner, Repository.last)
        assert_equal 3, @repository.content_memberships.length
      end
    end
  end

  def do_show_get(repos)
    get :show, :project_id => @project.slug, :id => repos.name
  end

  def do_clone_get
    get :clone, :project_id => @project.slug, :id => @repository.name
  end

  def do_create_clone_post(opts={})
    post(:create_clone, {
        :project_id => @project.slug,
        :id => @repository.name,
        :repository => { :owner_type => "User" }.merge(opts)
      })
  end

  def do_writable_by_get(options={})
    post(:writable_by, {
        :project_id => @project.slug,
        :id => @repository.name,
        :username => "johan"
      }.merge(options))
  end

  def do_config_get(options={})
    get(:repository_config, {:project_id => @project.slug, :id => @repository.name}.merge(options))
  end

  def do_delete(repos)
    delete :destroy, :project_id => @project.slug, :id => repos.name
  end
end
