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

class CommentsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context

  should_enforce_ssl_for(:get, :create)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :new)
  should_enforce_ssl_for(:post, :create)
  should_enforce_ssl_for(:post, :preview)

  def setup
    @project = projects(:johans)
    @repository = repositories(:johans)
  end

  context "#index" do
    should "scopes to project.repositories" do
      get :index, :project_id => @project.to_param, 
        :repository_id => @repository.to_param
      assert_response :success
      assert !assigns(:comments).include?(comments(:moes_repos))
    end
  end
  
  context "#new" do    
    should "requires login" do
      session[:user_id] = nil
      get :new, :project_id => @project.slug, 
        :repository_id => @repository.name
      assert_redirected_to (new_sessions_path)
    end
    
    should "is successfull" do
      login_as :johan
      get :new, :project_id => @project.slug, 
        :repository_id => @repository.name
      assert_response :success
      assert_equal @repository, assigns(:comment).target
    end
  end
  
  context "#create" do    
    should "requires login" do
      session[:user_id] = nil
      get :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :comment => {}
      assert_redirected_to (new_sessions_path)
    end
    
    should "scopes to the repository" do
      login_as :johan
      get :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :comment => { :body => "blabla" }
      assert_equal @repository, assigns(:comment).target
    end
    
    should "assigns the comment to the current_user" do
      login_as :johan
      get :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :comment => { :body => "blabla" }
      assert_equal users(:johan), assigns(:comment).user
    end
    
    should "creates the record on successful data" do
      login_as :johan
      assert_difference("Comment.count") do
        get :create, :project_id => @project.slug, 
          :repository_id => @repository.name, :comment => { :body => "moo" }
        assert_redirected_to (project_repository_comments_path(@project, @repository))
        assert_match(/your comment was added/i, flash[:success])
      end
    end
    
    should "it re-renders on invalid data" do
      login_as :johan
      get :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :comment => {:body => nil}
      assert_response :success
      assert_template("comments/new")
    end    
  end
  
  context 'preview' do
    should 'render a preview of the comment' do
      login_as :johan
      post :preview, :project_id => @project.slug, :repository_id => @repository.name, :comment => {:body => 'Foo'}
      assert_response :success
      assert_template("comments/preview")
    end
  end
  
  context "polymorphic creation" do
    setup do
      login_as :johan
      assert @merge_request = @repository.merge_requests.first
    end
    
    should "find set the repository as the polymorphic parent by default" do
      get :new, :project_id => @project.slug, :repository_id => @repository.to_param
      assert_response :success
      assert_equal @repository, assigns(:target)
      assert_equal @repository, assigns(:comment).target
    end
    
    should "find set the polymorphic parent by default, for merge requests" do
      get :new, :project_id => @project.slug, :repository_id => @repository.to_param,
        :merge_request_id => @merge_request.to_param
      assert_response :success
      assert_equal @merge_request, assigns(:target)
      assert_equal @merge_request, assigns(:comment).target
    end

    context "Inline commenting on commits" do
      setup do
        @repo = repositories(:johans)
        commit = mock(:parents => [])
        git = mock(:commit => commit)
        Repository.any_instance.stubs(:git).returns(git)
        login_as :moe
      end

      should "render a json response when created" do
        post :create, :project_id => @repo.project.to_param, :repository_id => @repo.to_param,
        :comment => {
          :sha1 => "ffca00",
          :path => "test/functional/comments_controller_test.rb",
          :lines => "135-135:135-138+3",
          :target_id => @repo.id,
          :target_type => @repo.class.name,
          :body => "Now this is a useful feature"
        }, :format => "js"
        assert_response :success
        result = JSON.parse(@response.body)
        assert_not_nil result["comment"]
      end
    end
    
    context "Watching a merge request" do
      setup do
        @repo = @merge_request.target_repository
        @project = @repo.project
        @user = users(:moe)
      end
      
      should "be watched when user wants it" do
        login_as @user
        assert_incremented_by(@user.favorites, :size, 1) do
          post(:create, :project_id => @project.to_param,
            :repository_id => @repo.to_param,
            :merge_request_id => @merge_request.to_param,
            :comment => {
              :body => "This feature is highly anticipated!"
            },
            :add_to_favorites => "1")
          @user.favorites.reload
        end
      end

      should "only be watched if so wanted" do
        login_as @user
        @controller.expects(:add_to_favorites).never
        post(:create, :project_id => @project.to_param,
          :repository_id => @repo.to_param,
          :merge_request_id => @merge_request.to_param,
          :comment => {
            :body => "This feature is highly anticipated!"
          })
      end
    end

    context "Listing merge request comments" do
      setup do
        @merge_request.comments.destroy_all
        @comment = @merge_request.comments.create!(:body => "Awesome",
          :project => @project, :user => @merge_request.user)
      end

      should "list the MR comments in #index" do
        get(:index, :project_id => @project.slug, :repository_id => @repository.to_param,
          :merge_request_id => @merge_request.to_param
          )
        assert_response :success
        assert_equal(@merge_request, assigns(:target))
        #assert_equal([@comment], assigns(:comments))
      end
    end
    
    context "Merge request versions" do
      should "set the merge request version as polymorphic parent" do
        @version = create_new_version
        create_merge_request_version_comment(@version)
        assert @controller.send(:applies_to_merge_request_version?)
        assert_response :success
        assert_equal @version, assigns(:target)
        assert_equal @version, assigns(:comment).target
        assert_equal("1-1:13-13+14", assigns(:comment).lines)
        assert_equal(("ffac01".."ffab99"), assigns(:comment).sha_range)
      end

      should "not notify the merge request owner, if he is the one commenting" do
        assert_no_difference("@merge_request.user.received_messages.count") do
          @version = create_new_version
          create_merge_request_version_comment(@version)
        end
      end

      should "notify the merge request owner of comments" do
        login_as :mike
        @version = create_new_version
        create_merge_request_version_comment(@version)
        assert message = @merge_request.user.received_messages.last
        assert_equal @merge_request.versions.last, message.notifiable
      end

      should "only notify the merge request owner once" do
        login_as :mike
        assert_difference("@merge_request.user.received_messages.count", 1) do
          @version = create_new_version
          create_merge_request_version_comment(@version)
        end
      end

      should "create an event with the MergeRequest class name as the body" do
        @version = create_new_version
        assert_difference("Event.count") do
          create_merge_request_version_comment(@version)
        end
        assert_equal @merge_request, Event.last.target, Event.last.inspect
        assert_equal "MergeRequest", Event.last.body
        assert_not_nil comment = Comment.find_by_id(Event.last.data)
        assert_equal "1-1:13-13+14", comment.lines
      end

      should "render some json if it is a merge request comment" do
        @version = create_new_version
        create_merge_request_version_comment(@version)
        assert_response :success
        assert_equal "application/json", @response.content_type
        json = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil json["file-diff"]
        assert_not_nil json["comment"]
      end

      should "be added to current_user's favorites if she wants" do
        @version = create_new_version
        create_merge_request_version_comment(@version, :add_to_favorites => "1")
        user = users(:johan)
        assert_equal(@merge_request, user.favorites.reload.last.watchable)
      end
    end

    should "redirect back to the merge request on POST create if that is the target" do
      post :create, :project_id => @project.slug, :repository_id => @repository.to_param,
        :merge_request_id => @merge_request.to_param, :comment => {:body => "awesome"}
      assert_response :redirect
      assert_equal @merge_request, assigns(:target)
      assert_equal @merge_request, assigns(:comment).target
      assert_redirected_to project_repository_merge_request_path(@project,
        @repository, @merge_request)
    end

    should "create an event the parent class name as the body" do
      assert_difference("Event.count") do
        post :create, :project_id => @project.slug, :repository_id => @repository.to_param,
          :merge_request_id => @merge_request.to_param, :comment => {:body => "awesome"}
      end
      assert_equal @merge_request, Event.last.target
      assert_equal "MergeRequest", Event.last.body
    end

    should "create only one event when changing state on a merge request thru comment" do
      assert_incremented_by(Event, :count, 1) do
        post :create, :project_id => @project.slug, :repository_id => @repository.to_param,
          :merge_request_id => @merge_request.to_param, :comment => {:body => "awesome", :state => "merged"}
      end
    end
    
    should 'transition the target if state is provided' do
      post :create, :project_id => @project.slug, :repository_id => @repository.to_param,
        :merge_request_id => @merge_request.to_param, :comment => {:body => 'Yeah, right', :state => 'Resolved'}
      assert_equal [nil, 'Resolved'], assigns(:comment).state_change
      assert_equal 'Resolved', @merge_request.reload.status_tag.name
    end
    
    should 'not transition the target if an empty state if provided' do
      post :create, :project_id => @project.slug, :repository_id => @repository.to_param,
        :merge_request_id => @merge_request.to_param, :comment => {:body => 'Yeah, right', :state => ''}
      assert_nil @merge_request.reload.status_tag
    end
    
    should 'not allow other users than the merge request owner to change the state' do
      login_as :mike
      post :create, :project_id => @project.slug, :repository_id => @repository.to_param,
        :merge_request_id => @merge_request.to_param, :comment => {:body => 'Yeah, right', :state => 'Resolved'}
      assert_response :redirect
      assert_nil @merge_request.reload.status_tag
    end
  end

  context 'Changing a comment' do
    setup {
      @user = users(:moe)
      @repo = repositories(:moes)
      @comment = Comment.create(:project => @repo.project, :user => @user,
        :target => @repo, :body => "Looks like progress")
      @get_edit = proc { get(:edit, :project_id => @repo.project.to_param,
          :repository_id => @repo.to_param, :id => @comment.to_param) }
    }
    
    context "GET to #edit" do
      should 'let the owner edit his own comment' do
        login_as @user.login
        @get_edit.call
        assert_response :success
        assert_equal @comment, assigns(:comment)
      end
      
      should 'not let other users edit the comment' do
        login_as :mike
        @get_edit.call
        assert_response :unauthorized
      end
    end

    context 'PUT to #update' do
      should 'update the comment' do
        login_as @user.login
        new_body = "I take that back. This sucks"
        put(:update, :project_id => @repo.project.to_param,
          :repository_id => @repo.to_param, :id => @comment.to_param,
          :comment => {:body => new_body})
        assert_response :success
        assert_equal new_body, @comment.reload.body
      end
    end
  end

  protected
  def create_new_version
    diff_backend = mock
    diff_backend.stubs(:commit_diff).returns([])
    MergeRequestVersion.any_instance.stubs(:diff_backend).returns(diff_backend)
    @merge_request.stubs(:calculate_merge_base).returns("ffac0")
    version = @merge_request.create_new_version
    return version
  end

  def create_merge_request_version_comment(version, extra_options={})
    request_options = {
      :project_id => @project.slug,
      :repository_id => @repository.to_param,
      :merge_request_version_id => version.to_param,
      :comment => {
        :path => "LICENSE",
        :lines => "1-1:13-13+14",
        :sha1 => "ffac01-ffab99",
        :body => "Needs more cowbell"},
      :format => "js"}.merge(extra_options)
    post :create, request_options
  end
end
