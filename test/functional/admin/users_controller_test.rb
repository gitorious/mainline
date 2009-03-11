# encoding: utf-8

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::UsersControllerTest < ActionController::TestCase
  
  def setup
    login_as :johan
  end
  
  should "GET /admin/users" do
    get :index
    assert_response :success
    assert_match(/Create New User/, @response.body)
  end
  
  should "GET /admin/users/new" do
    get :new
    assert_response :success
    assert_match(/Is Administrator/, @response.body)
  end

  should "POST /admin/users" do
    assert_difference("User.count") do
      post :create, :user => valid_admin_user
    end
    assert_redirected_to(admin_users_path)
    assert_nil flash[:error]
  end

  should "PUT /admin/users/1/suspend" do
    assert users(:johan).suspended_at.nil?, 'nil? should be true'
    put :suspend, :id => users(:johan).to_param
    assert_equal users(:johan), assigns(:user)
    users(:johan).reload
    assert_not_nil users(:johan).suspended_at
    assert_response :redirect
    assert_redirected_to(admin_users_url)
  end

  should "PUT /admin/users/1/unsuspend" do
    users(:johan).suspended_at = Time.new
    users(:johan).save
    put :unsuspend, :id => users(:johan).to_param
    assert_equal users(:johan), assigns(:user)
    users(:johan).reload
    assert_nil users(:johan).suspended_at
    assert_response :redirect
    assert_redirected_to(admin_users_url)
  end

  should " not access administrator pages if not admin" do
    login_as :mike
    get :index
    assert_redirected_to(root_path)
    assert_equal "For Administrators Only", flash[:error]
    get :new
    assert_redirected_to(root_path)
    assert_equal "For Administrators Only", flash[:error]
  end
  
  context "#reset_password" do
    should "redirects to forgot_password if nothing was found" do
      post :reset_password, :user => {:email => "xxx"}
      assert_redirected_to(admin_users_path)
      assert_match(/invalid email/i, flash[:error])
    end
    
    should "sends a new password if email was found" do
      u = users(:johan)
      User.expects(:generate_random_password).returns("secret")
      Mailer.expects(:deliver_forgotten_password).with(u, "secret")
      post :reset_password, :user => {:email => u.email}
      assert_redirected_to(admin_users_path)
      assert_equal "A new password has been sent to your email", flash[:notice]
      
      assert_not_nil User.authenticate(u.email, "secret")
    end
  end
  
  
  def valid_admin_user
    { :login => 'johndoe', :email => 'foo@foo.com', :password => 'johndoe', :password_confirmation => 'johndoe', :is_admin => "1"}
  end
end
