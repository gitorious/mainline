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

class PasswordResetsControllerTest < ActionController::TestCase
  should "allow anonymous access to password reminder page" do
    get :new

    assert_response :success
    assert_template "password_resets/new"
  end

  context "#generate_token" do
    should "redirect to forgot password if nothing was found" do
      post :generate_token, :user => { :email => "xxx" }

      assert_redirected_to(forgot_password_users_path)
      assert_match(/invalid email/i, flash[:error])
    end

    should "redirect to root after resetting password" do
      u = users(:johan)

      post :generate_token, :user => { :email => u.email }

      assert_redirected_to(root_path)
      assert_match(/A password confirmation link has been sent/, flash[:success])
    end

    should "notify non-activated users that they need to activate their accounts before resetting the password" do
      user = users(:johan)
      user.update_attribute(:activation_code, "????")

      post :generate_token, :user => { :email => user.email }

      assert_redirected_to forgot_password_users_path
      assert_match(/activated yet/, flash[:error])
    end
  end

  context "#reset" do
    setup do
      @user = users(:johan)
      @user.update_attribute(:password_key, "s3kr1t")
    end

    should "redirect if the token is invalid" do
      get :prepare_reset, :token => "invalid"

      assert_response :redirect
      assert_redirected_to forgot_password_users_path
      assert_not_nil flash[:error]
    end

    should "render the form if the token is valid" do
      get :prepare_reset, :token => "s3kr1t"

      assert_response :success
      assert_nil flash[:error]
    end

    should "re-render if password confirmation does not match" do
      put :reset, :token => "s3kr1t", :user => {
        :password => "qwertyasdf",
        :password_confirmation => "asdf"
      }

      assert_response :success
      assert_nil User.authenticate(@user.email, "qwertyasdf")
    end

    should "update the password" do
      put :reset, :token => "s3kr1t", :user => {
        :password => "qwertyasdf",
        :password_confirmation => "qwertyasdf"
      }

      assert_response :redirect
      assert_redirected_to new_sessions_path
      assert User.authenticate(@user.email, "qwertyasdf")
      assert_match(/Password updated/i, flash[:success])
    end
  end

  context "in Private Mode" do
    setup do
      @test_settings = Gitorious::Configuration.prepend("public_mode" => false)
    end

    teardown do
      Gitorious::Configuration.prune(@test_settings)
    end

    should "GET forgot password page" do
      get :new
      assert_response :success
    end
  end
end
