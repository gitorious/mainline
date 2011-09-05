require 'test_helper'

class Admin::RepositoriesControllerTest < ActionController::TestCase
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:put, :recreate)

  context "Un-ready repositories" do
    should "deny access for regular users" do
      get :index
      assert_response :redirect
    end

    should "grant access to site admins" do
      login_as :johan
      get :index
      assert_response :success
    end

    should "re-post the creation message" do
      login_as :johan
      @repo = repositories(:johans)
      Repository.expects(:find).with("2").returns(@repo)
      @repo.expects(:post_repo_creation_message)
      put :recreate, :id => 2
      assert_response :redirect
    end
  end

  context "pagination" do
    setup { login_as :johan }
    should_scope_pagination_to(:index, Repository)
  end
end
