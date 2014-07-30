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

  def ready_repository
    head = Object.new
    def head.commit; "abcdef"; end
    Repository.any_instance.stubs(:head).returns(head)
    @repo.update_attribute(:ready, true)
    @repo.save
    @repo
  end

  should_render_in_site_specific_context

  context "#show" do
    should "temporarily redirect to the repository browser" do
      get :show, :project_id => @project.to_param, :id => ready_repository.to_param

      assert_response 307
      assert_redirected_to "/johans-project/johansprojectrepos/source/abcdef:"
    end

    should "issue a Refresh header if repo is not ready yet" do
      @repo.update_attribute(:ready, false)
      @repo.save
      get :show, :project_id => @project.to_param, :id => @repo.to_param
      assert_response :success
      assert_not_nil @response.headers["Refresh"]
    end

    should "render repository as XML" do
      get :show, :project_id => @project.to_param, :id => ready_repository.to_param, :format => "xml"
      assert_response :success
    end

    should "respond with proper go-import meta tag when go-get param is present" do
      get :show, :project_id => @project.to_param, :id => ready_repository.to_param, 'go-get' => 1

      assert_response 200
      assert_tag tag: 'meta', attributes: { name: 'go-import', content: 'gitorious.test/johans-project/johansprojectrepos git http://gitorious.test/johans-project/johansprojectrepos.git' }
    end

  end

  context "#index" do
    setup do
      @project = projects(:johans)
    end

    should "redirects html requests to project index" do
      get :index, :project_id => @project.slug
      assert_response :redirect
      assert_redirected_to(project_path(@project))
    end

    should "render xml if requested" do
      get :index, :project_id => @project.slug, :format => "xml"
      assert_response :success
    end
  end

  context "Searching" do
    setup do
      @project = projects(:johans)
    end

    should "render repositories matching a search term" do
      get :index, :project_id => @project.to_param, :filter => "clone", :format => "json"
      assert_response :success
      assert_match repositories(:johans2).name, @response.body
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

    should "GETs edit successfully" do
      get :edit, :project_id => @project.to_param, :id => @repository.to_param

      assert_response :success
      assert_match @repository.name, @response.body
      assert_match "nonpack", @response.body
      assert_match "test/master", @response.body
      assert_match "test/chacon", @response.body
      assert_match "testing", @response.body
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
        put(:update, {
          :project_id => @project.to_param,
          :id => @repository.to_param,
          :repository => { :head => the_head.name }
        })
      end
    end
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

    should "allow authorize users to get project repositories" do
      login_as :johan
      get :index, :project_id => @project.to_param
      assert_response :redirect
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
      get :index, :project_id => @project.to_param, :format => "json"
      assert_equal 1, JSON.parse(@response.body).length
    end

    should "exclude filtered private repositories in project" do
      get :index, :project_id => @project.to_param, :filter => "o", :format => "json"
      assert_equal 1, JSON.parse(@response.body).length
    end

    should "include authorized private repositories in project" do
      login_as :johan
      get :index, :project_id => @project.to_param
      assert_redirected_to(project_path(@project))
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
  end

  def do_delete(repos)
    delete :destroy, :project_id => @project.slug, :id => repos.name
  end
end
