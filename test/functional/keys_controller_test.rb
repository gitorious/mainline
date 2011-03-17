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

class KeysControllerTest < ActionController::TestCase
  
  should_render_in_global_context
  
  def setup
    @user = users(:johan)
    SshKey.any_instance.stubs(:valid_key_using_ssh_keygen?).returns(true)
  end
  
  should_enforce_ssl_for(:delete, :destroy)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :new)
  should_enforce_ssl_for(:get, :show)
  should_enforce_ssl_for(:post, :create)

  context "index" do
    setup do
      login_as :johan
    end
  
    should "requires login" do
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
  
    should "GET account/keys is successful" do
      get :index, :user_id => @user.to_param
      assert_response :success
    end
  
    should "scopes to the current_users keys" do
      get :index, :user_id => @user.to_param
      assert_equal users(:johan).ssh_keys, assigns(:ssh_keys)
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

  context "new" do
  
    setup do
      login_as :johan
    end
  
    should " require login" do
      session[:user_id] = nil
      get :new
      assert_redirected_to (new_sessions_path)
    end
    
    should "require current_user" do
      login_as :moe
      get :new, :user_id => @user.to_param
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end
  
    should "GET account/keys is successful" do
      get :new, :user_id => @user.to_param
      assert_response :success
    end
  
    should "scopes to the current_user" do
      get :new, :user_id => @user.to_param
      assert_equal users(:johan).id, assigns(:ssh_key).user_id
    end
  end

module KeyStubs
    def valid_key
    <<-EOS
ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFz
c2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRi
Z2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4
Zm9mcWU= foo@example.com
EOS
    end

    def invalid_key
      "ooger booger wooger@burger"
    end
end

  context "create" do
    include KeyStubs
  
    setup do
      login_as :johan
    end
  
    should " require login" do
      session[:user_id] = nil
      post :create, :ssh_key => {:key => valid_key}
      assert_redirected_to(new_sessions_path)
    end
    
    should "require current_user" do
      login_as :moe
      post :create, :ssh_key => {:key => valid_key}, :user_id => @user.to_param
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end
  
    should "scopes to the current_user" do
      post :create, :ssh_key => {:key => valid_key}, :user_id => @user.to_param
      assert_equal users(:johan).id, assigns(:ssh_key).user_id
    end
  
    should "POST account/keys/create is successful" do
      post :create, :ssh_key => {:key => valid_key}, :user_id => @user.to_param
      assert_response :redirect
    end

    should "publish a creation message to the message queue" do
      SshKey.any_instance.expects(:publish_creation_message)
      post :create, :ssh_key => {:key => valid_key}, :user_id => @user.to_param
      assert_response :redirect
    end
  end

  context "create.xml" do
    include KeyStubs
  
    setup do
      authorize_as :johan
    end
  
    should " require login" do
      authorize_as(nil)
      post :create, :ssh_key => {:key => valid_key}, :format => "xml", :user_id => @user.to_param
      assert_response 401
    end
    
    should "require current_user" do
      login_as :moe
      post :create, :ssh_key => {:key => valid_key}, :user_id => @user.to_param, :format => "xml"
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end
  
    should "scopes to the current_user" do
      post :create, :ssh_key => {:key => valid_key}, :format => "xml", :user_id => @user.to_param
      assert_equal users(:johan).id, assigns(:ssh_key).user_id
    end
  
    should "POST account/keys/create is successful" do
      post :create, :ssh_key => {:key => valid_key}, :format => "xml", :user_id => @user.to_param
      assert_response 201
    end
  end
end
