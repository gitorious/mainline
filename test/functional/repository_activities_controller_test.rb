# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
class RepositoryActivitiesControllerTest < ActionController::TestCase
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

  context "#index" do
    should "successfully list activities" do
      @repo.stubs(:git).returns(stub_everything("git mock"))
      get :index, :project_id => @project.to_param, :id => @repo.to_param
      assert_response :success
    end

    should "require repository to belong to project" do
      repo = repositories(:moes)
      repo.stubs(:git).returns(stub_everything("git mock"))
      get :index, :project_id => @project.to_param, :id => repo.to_param
      assert_response 404
    end

    should "find the project repository" do
      get :index, :project_id => @project.to_param, :id => @repo.to_param
      assert_response :success
      assert_match @project.slug, @response.body
      assert_match @repo.name, @response.body
    end

    context "with committer (not owner) logged in" do
      should_eventually "see a merge request link" do
        login_as :mike
        committership = @repo.committerships.new
        committership.committer = users(:mike)
        committership.permissions = Committership::CAN_REVIEW | Committership::CAN_COMMIT
        committership.save!

        Project.expects(:find_by_slug!).with(@project.slug).returns(@project)
        @repo.stubs(:has_commits?).returns(true)

        get :index, :project_id => @project.to_param, :id => @repo.to_param
        assert_equal(nil, flash[:error])
        # Old markup...
        assert_select("#sidebar ul.links li a[href=?]",
          new_project_repository_merge_request_path(project, repository),
          :content => "Request merge")
      end
    end

    should "not display git:// link when disabling the git daemon" do
      Gitorious.stubs(:git_daemon).returns(nil)
      @repo.update_attribute(:ready, true)

      get :index, :project_id => @project.to_param, :id => @repo.to_param

      assert_no_match(/git:\/\//, @response.body)
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories
      @group = groups(:team_thunderbird)
      @repository = @project.repositories.first
      Repository.any_instance.stubs(:has_commits?).returns(true)
    end

    should "disallow unauthorized users to show repository" do
      get :index, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized users to get show repository" do
      login_as :johan
      get :index, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
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

    should "disallow unauthorized users to show repository" do
      get :index, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized users to get show repository" do
      login_as :johan
      get :index, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end

    should "allow site admin to get show repository" do
      user = users(:mike)
      user.is_admin = true
      user.save
      login_as :mike
      get :index, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end
  end
end
