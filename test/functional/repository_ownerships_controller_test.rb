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

class RepositoryOwnershipsControllerTest < ActionController::TestCase
  def setup
    @settings = Gitorious::Configuration.prepend("enable_private_repositories" => false)
    setup_ssl_from_config
    @grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(@grit)
    @project = projects(:johans)
  end

  teardown do
    Gitorious::Configuration.prune(@settings)
  end

  context "edit / update" do
    setup do
      @repository = @project.repositories.mainlines.first
      login_as :johan
    end

    should "require login" do
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
      get :edit, :project_id => @repository.project.to_param, :id => @repository.to_param
      assert_response :success
    end

    should "GETs edit successfully" do
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response :success

      assert_match "A-team", @response.body
    end

    should "change the owner" do
      group = groups(:team_thunderbird)
      group.add_member(users(:johan), Role.admin)

      put(:update, {
          :project_id => @project.to_param,
          :id => @repository.to_param,
          :repository => { :owner_id => group.id }
        })

      assert_redirected_to(project_repository_path(@repository.project, @repository))
      assert_equal group, @repository.reload.owner
    end

    should "not change the owner if owned by a group" do
      group = groups(:team_thunderbird)
      group.add_member(users(:johan), Role.admin)
      @repository.owner = group
      @repository.kind = Repository::KIND_TEAM_REPO
      @repository.save!
      new_group = Group.create!(:name => "temp")
      new_group.add_member(users(:johan), Role.admin)

      put(:update, {
          :project_id => @repository.project.to_param,
          :id => @repository.to_param,
          :repository => { :owner_id => new_group.id }
        })

      assert_response :redirect
      assert_redirected_to(project_repository_path(@project, @repository))
      assert_equal group, @repository.reload.owner
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories
      @group = groups(:team_thunderbird)
      @repository = @project.repositories.first
      Repository.any_instance.stubs(:has_commits?).returns(true)
    end

    should "disallow unauthorized user to transfer ownership" do
      login_as :mike
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized user to transfer ownership" do
      login_as :johan
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
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

    should "disallow unauthorized user to transfer ownership" do
      login_as :mike
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 403
    end

    should "allow authorized user to transfer ownership" do
      login_as :johan
      get :edit, :project_id => @project.to_param, :id => @repository.to_param
      assert_response 200
    end
  end
end
