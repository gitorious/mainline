# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class CommittershipsControllerTest < ActionController::TestCase
  def setup
    setup_ssl_from_config
    @project = projects(:johans)
    @group = groups(:team_thunderbird)
    @user = users(:johan)
    @repository = repositories(:johans)
    login_as :johan
  end

  should_render_in_site_specific_context

  context "GET index" do
    should "require login" do
      logout
      get :index, params
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_redirected_to(project_repository_path(@project, @repository))
    end

    should "require administrator" do
      @repository.owner = @group
      @repository.save!
      assert !admin?(users(:mike), @repository)
      login_as :mike
      get :index, :project_id => @project.to_param, :repository_id => @repository.to_param
      assert_redirected_to(project_repository_path(@project, @repository))
      assert_match(/only repository admins are allowed/, flash[:error])
    end

    should "finds the owner (a Project) and the repository" do
      get :index, params
      assert_response :success
      assert_equal @project, assigns(:owner)
      assigns(:repository) == @repository
    end

    should "lists the committerships" do
      repo = repositories(:moes)
      repo.owner = @group
      repo.committerships.update_owner(@group)
      repo.save!
      @group.add_member(@user, Role.admin)
      assert admin?(@user, repo)

      get :index, :project_id => repo.project.to_param, :repository_id => repo.to_param
      assert_response :success

      repo.committerships.groups.each do |cs|
        assert_match cs.committer.title, @response.body
      end
    end
  end

  context "POST create" do
    include FakeUseCaseHelper

    should "add a Group as having committership" do
      committership = Committership.new(committer: @group)
      AddCommitter.stubs(:new)
                  .with(@user, @repository)
                  .returns(fake_use_case(success: committership))

      post :create, params(:group => {:name => @group.name}, :user => {}, :permissions => ["review"])
      assert_response :redirect
      assert_equal "New collaborator added.", flash[:success]
    end

    should "add a User as having committership" do
      committership = Committership.new(committer: @user)
      AddCommitter.stubs(:new)
                  .with(@user, @repository)
                  .returns(fake_use_case(success: committership))

      post :create, {
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :user => {:login => users(:moe).login}, :group => {},
        :permissions => ["review","commit"]
      }
      assert_nil flash[:error]
      assert_response :redirect
      assert_equal "New collaborator added.", flash[:success]
    end

    should "not fail when the same user is added twice" do
      committership = Committership.new(committer: @user)
      AddCommitter.stubs(:new)
                  .with(@user, @repository)
                  .returns(fake_use_case(failure: committership))

      post :create, params(
        :group => {},
        :user => { :login => users(:johan).login},
        :permissions => ["review"]
      )
      assert_response :success
    end
  end

  should "GET edit" do
    @committership = @repository.committerships.new_committership
    @committership.committer = users(:mike)
    @committership.permissions = Committership::CAN_REVIEW
    @committership.save!

    get :edit, params(:id => @committership.to_param)

    assert_response :success
    assert_match "mike", @response.body
    assert_template("committerships/edit")
  end

  should "PUT update" do
    @committership = @repository.committerships.new_committership
    @committership.committer = users(:mike)
    @committership.permissions = (Committership::CAN_REVIEW | Committership::CAN_COMMIT)
    @committership.save!

    get :update, params(:id => @committership.to_param, :permissions => ["review"])

    assert_response :redirect
    assert_equal [:review], @committership.reload.permission_list
  end

  context "DELETE destroy" do
    should "require login" do
      logout
      delete :destroy, params(:id => Committership.first.id)
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_redirected_to(project_repository_path(@project, @repository))
    end

    should "delete committership" do
      committership = @repository.committerships.create!({
        :committer => @group,
        :creator => @user
      })
      assert_difference("@repository.committerships.count", -1) do
        delete :destroy, params(:id => committership.id)
      end
      assert_match(/The collaborator was removed/, flash[:notice])
      assert_response :redirect
    end
  end

  context "with authorization" do
    setup do
      @repository = repositories(:johans2)
      @committership = @repository.committerships.create_with_permissions!({
        :committer => users(:mike)
      }, Committership::CAN_ADMIN)
    end

    context "private projects" do
      setup do
        enable_private_repositories(@repository.project)
        login_as :mike
      end

      should "require project access to index" do
        get :index, params
        assert_response 403
      end

      should "require project access to create" do
        post :create, params(:group => { :name => @group.name }, :user => {}, :permissions => ["review"])
        assert_response 403
      end

      should "require project access to edit" do
        get :edit, params(:id => @committership.to_param)
        assert_response 403
      end

      should "require project access to update" do
        put :update, params(:id => @committership.to_param, :permissions => ["review"])
        assert_response 403
      end

      should "require project access to destroy" do
        delete :destroy, params(:id => Committership.first.id)
        assert_response 403
      end
    end

    context "private repositories" do
      setup do
        enable_private_repositories(@repository)
        login_as :moe
      end

      should "require project access to index" do
        get :index, params
        assert_response 403
      end

      should "require project access to create" do
        post :create, params(:group => { :name => @group.name }, :user => {}, :permissions => ["review"])
        assert_response 403
      end

      should "require project access to edit" do
        get :edit, params(:id => @committership.to_param)
        assert_response 403
      end

      should "require project access to update" do
        put :update, params(:id => @committership.to_param, :permissions => ["review"])
        assert_response 403
      end

      should "require project access to destroy" do
        delete :destroy, params(:id => Committership.first.id)
        assert_response 403
      end
    end
  end

  private
  def params(additional = {})
    { :project_id => @project.to_param,
      :repository_id => @repository.to_param }.merge(additional)
  end
end
