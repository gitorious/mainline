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

class RepositoryClonesControllerTest < ActionController::TestCase
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

  should_render_in_site_specific_context

  context "#new" do
    setup do
      login_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
    end

    should "require login" do
      session[:user_id] = nil
      get_new
      assert_redirected_to(new_sessions_path)
    end

    should "GET projects/1/repositories/3/clone is successful" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      get_new

      assert_equal nil, flash[:error]
      assert_response :success
      assert_match @repository.name, @response.body
    end

    should "redirects to new_account_key_path if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan
      get_new
      assert_redirected_to(new_user_key_path(users(:johan)))
    end

    should "redirects with a flash if repos cannot be cloned" do
      login_as :johan
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(false)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      get_new

      assert_redirected_to(project_repository_path(@project, @repository))
      assert_match(/cannot clone an empty/i, flash[:error])
    end
  end

  context "#create" do
    setup do
      login_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
    end

    should "require login" do
      session[:user_id] = nil
      post_create
      assert_redirected_to(new_sessions_path)
    end

    should "post projects/1/repositories/3/create_clone is successful" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)

      post_create(:name => "foo-clone")

      assert_response :redirect
    end

    should "post projects/1/repositories/3/create_clone is successful sets the owner to the user" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      post_create(:name => "foo-clone", :owner_type => "User")

      assert_response :redirect
      assert_equal users(:johan), Repository.last.owner
      assert_equal Repository::KIND_USER_REPO, Repository.last.kind
    end

    should "post projects/1/repositories/3/create_clone is successful sets the owner to the group" do
      groups(:team_thunderbird).add_member(users(:johan), Role.admin)
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      post_create(:name => "foo-clone", :owner_type => "Group", :owner_id => groups(:team_thunderbird).id)

      assert_response :redirect
      assert_equal groups(:team_thunderbird), Repository.last.owner
      assert_equal Repository::KIND_TEAM_REPO, Repository.last.kind
    end

    should "redirects to new_user_key_path if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan

      post_create

      assert_redirected_to(new_user_key_path(users(:johan)))
    end

    should "redirects with a flash if repos cannot be cloned" do
      login_as :johan
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(false)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      post_create(:name => "foobar")

      assert_redirected_to(project_repository_path(@project, @repository))
      assert_match(/cannot clone an empty/i, flash[:error])
    end
  end

  context "#create as XML" do
    setup do
      authorize_as :johan
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
      @request.env["HTTP_ACCEPT"] = "application/xml"
    end

    should "require login" do
      authorize_as(nil)
      post_create(:name => "foo")
      assert_response 401
    end

    should "post projects/1/repositories/3/create_copy is successful" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(true)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)

      post_create(:name => "foo-clone")

      assert_response 201
    end

    should "renders text if repos cannot be cloned" do
      Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
      @repository.stubs(:has_commits?).returns(false)
      @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
      post_create(:name => "foobar")
      assert_response 422
      assert_match(/cannot clone an empty/i, @response.body)
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories
      @repository = @project.repositories.first
      Repository.any_instance.stubs(:has_commits?).returns(true)
    end

    should "disallow unauthenticated users to clone repo" do
      login_as :mike
      get_new
      assert_response 403
    end

    should "allow authenticated users to clone repo" do
      login_as :johan
      get_new
      assert_response 200
    end

    should "disallow unauthorized users to create clones" do
      login_as :mike
      post_create(:name => "foo-clone")
      assert_response 403
    end

    should "allow authorized users to create clones" do
      login_as :johan
      post_create(:name => "foo-clone")
      assert_response 302
    end
  end

  context "With private repositories" do
    setup do
      enable_private_repositories(@repo)
      @repository = @project.repositories.first
      Repository.any_instance.stubs(:has_commits?).returns(true)
    end

    teardown do
      user = users(:mike)
      user.is_admin = false
      user.save
    end

    should "disallow unauthenticated users to clone repo" do
      login_as :mike
      get_new
      assert_response 403
    end

    should "allow authenticated users to clone repo" do
      login_as :johan
      get_new
      assert_response 200
    end

    should "disallow unauthorized users to create clones" do
      login_as :mike
      post_create(:name => "foo-clone")
      assert_response 403
    end

    should "allow authorized users to create clones" do
      login_as :johan
      post_create(:name => "foo-clone")
      assert_response 302
    end

    context "cloning" do
      setup do
        login_as(:moe)
        Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
        @repository.stubs(:has_commits?).returns(true)
        @project.repositories.expects(:find_by_name!).with(@repository.name).returns(@repository)
      end

      should "clone private repository" do
        @repository.make_private
        @repository.add_member(users(:moe))
        post_create(:name => "foo-clone")
        assert Repository.last.private?
      end

      should "clone public repository" do
        post_create(:name => "foo-clone")
        assert !Repository.last.private?
      end

      should "add parent members to new repository" do
        @repository.make_private
        @repository.add_member(users(:moe))
        @repository.add_member(users(:old_timer))
        post_create(:name => "foo-clone")
        assert can_read?(users(:old_timer), Repository.last)
        assert can_read?(users(:moe), Repository.last)
        assert can_read?(@repository.owner, Repository.last)
        assert_equal 3, @repository.content_memberships.length
      end
    end
  end

  def get_new
    get :new, :project_id => @project.slug, :id => @repository.name
  end

  def post_create(opts={})
    post(:create, {
        :project_id => @project.slug,
        :id => @repository.name,
        :repository => { :owner_type => "User" }.merge(opts)
      })
  end
end
