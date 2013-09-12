# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "ssh_key_test_helper"

class KeysControllerTest < ActionController::TestCase
  include SshKeyTestHelper
  should_render_in_global_context

  def setup
    setup_ssl_from_config
    @user = users(:johan)
    SshKeyValidator.any_instance.stubs(:valid_key_using_ssh_keygen?).returns(true)
  end

  context "index" do
    setup do
      login_as :johan
    end

    should "require login" do
      session[:user_id] = nil
      get :index, :user_id => @user.to_param
      assert_response :redirect
      assert_redirected_to(new_sessions_path)
    end

    should "require current_user" do
      login_as :moe
      get :index, :user_id => @user.to_param
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end

    should "redirect from account/keys to new user edit page" do
      get :index, :user_id => @user.to_param
      assert_response :redirect
      assert_redirected_to user_edit_ssh_keys_path(@user)
    end
  end

  context "index.xml" do
    setup do
      authorize_as :johan
    end

    should "requires login" do
      authorize_as(nil)
      get :index, :format => "xml", :user_id => @user.to_param
      assert_response 401
    end

    should "require current_user" do
      login_as :moe
      get :index, :format => "xml", :user_id => @user.to_param
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end

    should "GET account/keys is successful" do
      get :index, :format => "xml", :user_id => @user.to_param
      assert_response :success
    end

    should "scopes to the current_users keys" do
      get :index, :format => "xml", :user_id => @user.to_param
      assert_equal users(:johan).ssh_keys.to_xml, @response.body
    end
  end

  context "create" do
    should "require login" do
      session[:user_id] = nil
      post :create, :user_id => "zmalltalker", :ssh_key => {:key => valid_key}
      assert_redirected_to new_sessions_path
    end

    should "require current_user" do
      login_as :moe
      post :create, :ssh_key => {:key => valid_key}, :user_id => @user.to_param
      assert_redirected_to user_path(users(:moe))
    end

    should "scope to the current user" do
      login_as :johan
      assert_difference "@user.ssh_keys.count" do
        post :create, :user_id => @user.to_param, :ssh_key => { :key => valid_key }
      end
    end

    should "POST account/keys/create successfully" do
      login_as :johan
      post :create, :user_id => @user.to_param, :ssh_key => {:key => valid_key}
      assert_redirected_to user_edit_ssh_keys_path(@user)
    end
  end

  context "create.xml" do
    should "require login" do
      post :create, :ssh_key => {:key => valid_key}, :format => "xml", :user_id => @user.to_param
      assert_response 401
    end

    should "require current_user" do
      login_as :moe

      post :create, :ssh_key => {:key => valid_key}, :user_id => @user.to_param, :format => "xml"
      assert_redirected_to user_path(users(:moe))
    end

    should "creates a new ssh key for current user" do
      login_as :johan

      assert_difference "@user.ssh_keys.count" do
        post :create, :ssh_key => {:key => valid_key}, :format => "xml", :user_id => @user.to_param
      end
    end

    should "POST account/keys/create successfully" do
      login_as :johan

      post :create, :ssh_key => {:key => valid_key}, :format => "xml", :user_id => @user.to_param
      assert_response :created
    end
  end
end
