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

require File.dirname(__FILE__) + '/../test_helper'

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
  should_enforce_ssl_for(:delete, :destroy)
  should_enforce_ssl_for(:get, :edit)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :new)
  should_enforce_ssl_for(:get, :update)
  should_enforce_ssl_for(:post, :create)

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
      get :index, :group_id => @group.to_param, :repository_id => @repository.to_param
      assert_redirected_to(group_repository_path(@group, @repository))
      assert_match(/only repository admins are allowed/, flash[:error])
    end

    should "finds the owner (a Project) and the repository" do
      get :index, params
      assert_response :success
      assert_equal @project, assigns(:owner)
      assigns(:repository) == @repository
    end

    should "finds the owner (a Group) and the repository" do
      @repository.owner = @group
      @repository.save!
      @group.add_member(@user, Role.admin)
      get :index, :group_id => @group.to_param, :repository_id => @repository.to_param
      assert_response :success
      assert_equal @group, assigns(:owner)
      assigns(:repository) == @repository
    end

    should "finds the owner (a User) and the repository" do
      @repository.owner = @user
      @repository.save!
      get :index, :user_id => @user.to_param, :repository_id => @repository.to_param
      assert_response :success
      assert_equal @user, assigns(:owner)
      assigns(:repository) == @repository
    end

    should "lists the committerships" do
      repo = repositories(:moes)
      repo.owner = @group
      cs = repo.committerships.first
      cs.build_permissions(:review,:commit,:admin)
      cs.save!
      repo.save!
      @group.add_member(@user, Role.admin)
      assert admin?(@user, repo)

      get :index, :group_id => @group.to_param, :repository_id => repo.to_param
      assert_response :success
      exp = repo.committerships.find(:all, :conditions => {
        :committer_type => "Group",
        :committer_id => @group.id
      })
      assert_equal exp, assigns(:committerships)
    end

    context "commitership pagination" do
      setup do
        login_as :johan
        @params = { :user_id => @user.to_param, :repository_id => @repository.to_param }
      end

      should_scope_pagination_to(:index, Committership, :delete_all => false)
    end
  end

  context "GET new" do
    should "is successful" do
      get :new, params
      assert_response :success
      assert_not_equal nil, assigns(:committership)
      assert_equal @repository, assigns(:committership).repository
      assert assigns(:committership).new_record?
    end

    should "scope to the correct repository" do
      repo = repositories(:johans2)
      repo.committerships.create_with_permissions!({
          :committer => users(:mike)
        }, Committership::CAN_ADMIN)
      login_as :mike
      get :new, :group_id => repo.owner.to_param,
        :project_id => repo.project.to_param,
      :repository_id => repositories(:johans2).to_param
      assert_response :success
      assert_not_equal nil, assigns(:committership)
      assert_equal repo, assigns(:committership).repository
      assert assigns(:committership).new_record?
    end
  end

  context "POST create" do
    should "add a Group as having committership" do
      assert_difference("@repository.committerships.count") do
        post :create, params(:group => {:name => @group.name}, :user => {}, :permissions => ["review"])
      end
      assert_response :redirect
      assert !assigns(:committership).new_record?, 'new_record? should be false'
      assert_equal @group, assigns(:committership).committer
      assert_equal @user, assigns(:committership).creator
      assert_equal "Team added as committers", flash[:success]
      assert_equal [:review], assigns(:committership).permission_list
    end

    should "add a User as having committership" do
      assert_difference("@repository.committerships.count") do
        post :create, {
          :project_id => @project.to_param,
          :repository_id => @repository.to_param,
          :user => {:login => users(:moe).login}, :group => {},
          :permissions => ["review","commit"]
        }
        assert_nil flash[:error]
        assert_response :redirect
      end
      assert !assigns(:committership).new_record?, 'new_record? should be false'
      assert_equal users(:moe), assigns(:committership).committer
      assert_equal @user, assigns(:committership).creator
      assert_equal "User added as committer", flash[:success]
      assert assigns(:committership).reviewer?
      assert assigns(:committership).committer?
      assert !assigns(:committership).admin?
    end
  end

  context "GET edit" do
    setup do
      @committership = @repository.committerships.create!({
          :committer => users(:mike),
          :permissions => Committership::CAN_REVIEW
        })
      get :edit, params(:id => @committership.to_param)
    end
    should_respond_with :success
    should_assign_to(:committership, :equals =>  @committership)
    should_render_template "edit"
  end

  context "PUT update" do
    setup do
      @committership = @repository.committerships.create!({
          :committer => users(:mike),
          :permissions => (Committership::CAN_REVIEW | Committership::CAN_COMMIT)
        })
      get :update, params(:id => @committership.to_param, :permissions => ["review"])
    end
    should_respond_with :redirect
    should_assign_to(:committership, :equals => @committership)

    should "update the permission" do
      assert_equal [:review], @committership.reload.permission_list
    end
  end

  context "DELETE destroy" do
    should "requires login" do
      logout
      delete :destroy, params(:id => Committership.first.id)
      assert_match(/only repository admins are allowed/, flash[:error])
      assert_redirected_to(project_repository_path(@project, @repository))
    end

    should "deletes the committership" do
      committership = @repository.committerships.create!({
        :committer => @group,
        :creator => @user
      })
      assert_difference("@repository.committerships.count", -1) do
        delete :destroy, params(:id => committership.id)
      end
      assert_match(/The committer was removed/, flash[:notice])
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

      should "require project access to new" do
        get :new, params(:group_id => @repository.owner.to_param)
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

      should "require project access to new" do
        get :new, params(:group_id => @repository.owner.to_param)
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
