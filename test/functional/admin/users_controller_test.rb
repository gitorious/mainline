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
# encoding: utf-8

require "test_helper"

class Admin::UsersControllerTest < ActionController::TestCase
  def setup
    setup_ssl_from_config
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
    assert users(:johan).suspended_at.nil?, "nil? should be true"
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
    users(:johan).reload
    assert_not_nil users(:johan).suspended_at
    assert_response :redirect
    assert_redirected_to(new_sessions_url)
  end

  should "not access administrator pages if not admin" do
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
      post :reset_password, :id => "invalid_user"
      assert_redirected_to(admin_users_path)
      assert_match(/invalid email/i, flash[:error])
    end

    should "sends a new password if email was found" do
      u = users(:johan)
      User.expects(:generate_random_password).returns("secret")
      Mailer.expects(:forgotten_password).with(u, "secret").returns(FakeMail.new)
      post :reset_password, :id => u.to_param
      assert_redirected_to(admin_users_path)
      assert_equal "A new password has been sent to your email", flash[:notice]

      assert_not_nil User.authenticate(u.email, "secret")
    end
  end

  context "users pagination" do
    should_scope_pagination_to(:index, User, :delete_all => false)
  end

  context "site admin status" do
    should "be flippable from admin user list" do
      u = users(:moe)
      assert !u.is_admin
      post :flip_admin_status, :id => u.to_param
      u.reload
      assert u.is_admin
      assert_redirected_to(admin_users_path)
    end
  end

  def valid_admin_user
    {
      :login => "johndoe",
      :email => "foo@foo.com",
      :password => "johndoe",
      :password_confirmation => "johndoe",
      :is_admin => "1",
      :terms_of_use => "1"
    }
  end
end
