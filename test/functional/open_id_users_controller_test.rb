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

class OpenIdUsersControllerTest < ActionController::TestCase
  should_render_in_global_context

  def setup
    setup_ssl_from_config
  end

  should "deny access unless OpenID information is present in the session" do
    get :new
    assert_response :redirect
  end

  should "render form with data from OpenID data in session" do
    get :new, {}, valid_session_options

    assert_response :success
    assert_match "schmoe", response.body
  end

  should "render the form unless all required fields are filled" do
    post :create, { :user => {} }, valid_session_options

    assert_response :success
    assert_template "open_id_users/new"
  end

  should "create a user with the provided credentials and openid url" do
    assert_incremented_by(ActionMailer::Base.deliveries, :size, 1) do
      post :create, { :user => {
          :fullname => "Moe Schmoe",
          :email => "moe@schmoe.example.com",
          :login => "schmoe",
          :terms_of_use => "1"
        }
      }, valid_session_options
      assert_response :redirect
    end

    user = User.last
    assert user.activated?
    assert user.terms_accepted?
    assert_nil session[:openid_url]
    assert_equal user, @controller.send(:current_user)
  end

  should "redirect to the dashboard on successful creation" do
    post :create, {
      :user => {
        :fullname => "Moe Schmoe",
        :email => "moe@schmoe.example.com",
        :login => "schmoe",
        :terms_of_use => "1"
      }
    }, valid_session_options

    assert_redirected_to "/"
  end

  should "deny access when open id is disabled" do
    Gitorious::OpenID.stubs(:enabled?).returns(false)
    get :new, {}, valid_session_options

    assert_response 403
  end

  should "disallow create when openid is disabled" do
    Gitorious::OpenID.stubs(:enabled?).returns(false)

    post :create, {
      :user => {
        :fullname => "Moe Schmoe",
        :email => "moe@schmoe.example.com",
        :login => "schmoe",
        :terms_of_use => "1"
      }
    }, valid_session_options

    assert_response 403
  end

  def valid_session_options
    { :openid_url => "http://moe.example.com/", :openid_nickname => "schmoe" }
  end
end
