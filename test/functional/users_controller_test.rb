# encoding: utf-8
#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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

class UsersControllerTest < ActionController::TestCase

  should " activate user" do
    assert_nil User.authenticate('moe', 'test')
    get :activate, :activation_code => users(:moe).activation_code
    assert_redirected_to('/')
    assert_not_nil flash[:notice]
    assert_equal users(:moe), User.authenticate('moe@example.com', 'test')
  end

  should "flashes a message when the activation code is invalid" do
    get :activate, :activation_code => "fubar"
    assert_redirected_to('/')
    assert_nil flash[:notice]
    assert_equal "Invalid activation code", flash[:error]
    assert_nil User.authenticate('moe@example.com', 'test')
  end

  context "Routing" do
    setup do
      @user = users(:johan)
    end
  
    should "recognizes routes starting with tilde as users/show/<name>" do
      assert_generates("/~#{@user.to_param}", {
        :controller => "users", 
        :action => "show", 
        :id => @user.to_param})
    
      assert_recognizes({
        :controller => "users", :action => "show", :id => @user.to_param
      }, {:path => "/~#{@user.to_param}", :method => :get})
    end
  
    should "doesn't recognize controller collection actions as repositories" do
      assert_recognizes({
        :controller => "users", :action => "forgot_password"
      }, {:path => "/users/forgot_password", :method => :get})
    end
  
    should "doesn't recognize controller member actions as repositories" do
      assert_recognizes({
        :controller => "users", :action => "activate", :activation_code => "123"
      }, {:path => "/users/activate/123", :method => :get})
    end
  end
  
  def create_user(options = {})
    post :create, :user => { :login => 'quire', :email => 'quire@example.com',
      :password => 'quire', :password_confirmation => 'quire' }.merge(options)
  end

  should " allow signups" do
    assert_difference("User.count") do
      create_user
      assert_response :redirect
    end
  end

  should " require login on signup" do
    assert_no_difference("User.count") do
      create_user(:login => nil)
      assert_not_nil assigns(:user).errors.on(:login)
      assert_template("users/new")
    end
  end

  should " require password on signup" do
    assert_no_difference("User.count") do
      create_user(:password => nil)
      assert !assigns(:user).errors.on(:password).empty?
      assert_template(("users/new"))
    end
  end

  should " require password confirmation on signup" do
    assert_no_difference("User.count") do
      create_user(:password_confirmation => nil)
      assert !assigns(:user).errors.on(:password_confirmation).empty?, 'empty? should be false'
      assert_template(("users/new"))
    end
  end

  should " require email on signup" do
    assert_no_difference("User.count") do
      create_user(:email => nil)
      assert !assigns(:user).errors.on(:email).empty?, 'empty? should be false'
      assert_template(("users/new"))
    end
  end

  should " be successful with valid data" do
    assert_difference("User.count") do
      create_user
    end
  end

  should "requires the user to activate himself after posting valid data" do
    create_user
    assert_equal nil, User.authenticate('quire@example.com', 'quire')
    assert !@controller.send(:logged_in?), 'controller.send(:logged_in?) should be false'
  end

  should "shows the user" do
    get :show, :id => users(:johan).login
    assert_response :success
    assert_equal users(:johan), assigns(:user)
  end
  
  should "not display the users email if he decides so" do
    user = users(:johan)
    user.update_attribute(:public_email, false)
    get :show, :id => user.to_param
    assert_response :success
    assert_select "#sidebar ul li.email", 0
  end

  should "recognizes routing with dots in it" do
    assert_recognizes({
      :controller => "users",
      :action => "show",
      :id => "j.s"
    }, "/users/j.s")
    assert_recognizes({
      :controller => "users",
      :action => "show",
      :id => "j.s"
    }, "/~j.s")
  end

  should "recognizes activate routes" do
    assert_recognizes({
      :controller => "users",
      :action => "activate",
      :activation_code => "abc123",
    }, "/users/activate/abc123")
  end

  should "counts the number of commits in the last week" do
    get :show, :id => users(:johan).login
    assert_response :success
    assert_instance_of Fixnum, assigns(:commits_last_week)
    assert (assigns(:commits_last_week) >= 0), '(assigns[:commits_last_week] >= 0) should be true'
  end

  should "#show sets atom feed autodiscovery" do
    user = users(:johan)
    get :show, :id => user.login
    assert_equal feed_user_path(user, :format => :atom), assigns(:atom_auto_discovery_url)
  end

  should "has an atom feed" do
    user = users(:johan)
    get :feed, :id => user.login, :format => "atom"
    assert_response :success
    assert_equal user, assigns(:user)
    assert_equal user.events.find(:all, :limit => 30, :order => "created_at desc"), assigns(:events)
  end

  context "#forgot_password" do
    should "GETs the page fine for everyone" do
      get :forgot_password
      assert_response :success
      assert_template(("forgot_password"))
    end
  end

  context "#reset_password" do
    should "redirects to forgot_password if nothing was found" do
      post :reset_password, :user => {:email => "xxx"}
      assert_redirected_to(forgot_password_users_path)
      assert_match(/invalid email/i, flash[:error])
    end
  
    should "sends a new password if email was found" do
      u = users(:johan)
      User.expects(:generate_random_password).returns("secret")
      Mailer.expects(:deliver_forgotten_password).with(u, "secret")
      post :reset_password, :user => {:email => u.email}
      assert_redirected_to(root_path)
      assert_equal "A new password has been sent to your email", flash[:notice]
    
      assert_not_nil User.authenticate(u.email, "secret")
    end
  end

  context "in Private Mode" do
    setup do
      GitoriousConfig['public_mode'] = false
    end

    teardown do
      GitoriousConfig['public_mode'] = true
    end
  
    should " activate user" do
      assert_nil User.authenticate('moe', 'test')
      get :activate, :activation_code => users(:moe).activation_code
      assert_redirected_to('/')
      assert !flash[:notice].nil?
      assert_equal users(:moe), User.authenticate('moe@example.com', 'test')
    end

    should "flashes a message when the activation code is invalid" do
      get :activate, :activation_code => "fubar"
      assert_redirected_to('/')
      assert_nil flash[:notice]
      assert_equal "Invalid activation code", flash[:error]
      assert_nil User.authenticate('moe@example.com', 'test')
    end
  
    should "GET /users/new" do
      get :new
      assert_redirected_to(root_path)
      assert_match(/Action requires login/, flash[:error])
    end
  
    should "GET /users/johan" do
      get :show, :id => users(:johan).to_param
      assert_redirected_to(root_path)
      assert_match(/Action requires login/, flash[:error])
    end
    
    should "GET /users/forgot_password" do
      get :forgot_password
      assert_response :success
    end
  end

  context "account-related tests" do
    setup do
      login_as :johan
    end
    
    should "require current_user" do
      login_as :moe
      get :edit, :id => users(:johan).to_param
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end
  
    should "GET /users/johan/edit is successful" do
      get :edit, :id => users(:johan).to_param
      assert_response :success
    end
  
    should "PUT /users/create with valid data is successful" do
      put :update, :id => users(:johan).to_param, :user => {
        :password => "fubar", 
        :password_confirmation => "fubar"
      }
      assert !flash[:notice].nil?
      assert_redirected_to(user_path(assigns(:user)))
    end

    should "GET require current_user" do
      login_as :moe
      get :password, :id => users(:johan).to_param
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end
  
    should "GET /users/johan/password is a-ok" do
      get :password, :id => users(:johan).to_param
      assert_response :success
      assert_equal users(:johan), assigns(:user)
    end
    
    should "PUT requires current_user" do
      login_as :moe
      put :update_password, :id => users(:johan).to_param, :user => {
        :current_password => "test", 
        :password => "fubar",
        :password_confirmation => "fubar" }
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end
  
    should "PUT /users/joan/update_password updates password if old one matches" do
      user = users(:johan)
      put :update_password, :id => user.to_param, :user => {
        :current_password => "test", 
        :password => "fubar",
        :password_confirmation => "fubar" }
      assert_redirected_to(user_path(user))
      assert_match(/Your password has been changed/i, flash[:notice])
      assert_equal user, User.authenticate(user.email, "fubar")
    end
  
    should "PUT /users/johan/update_password does not update password if old one is wrong" do
      put :update_password, :id => users(:johan).to_param, :user => {
        :current_password => "notthecurrentpassword", 
        :password => "fubar",
        :password_confirmation => "fubar" }
      assert_nil flash[:notice]
      assert_match(/doesn't seem to match/, flash[:error])
      assert_template("users/password")
      assert_equal users(:johan), User.authenticate(users(:johan).email, "test")
      assert_nil User.authenticate(users(:johan).email, "fubar")
    end
  
    should " be able to update password, even if user is openid enabled" do
      user = users(:johan)
      user.update_attribute(:identity_url, "http://johan.someprovider.com/")
      put :update_password, :id => user.to_param, :user => {
        :current_password => "test", 
        :password => "fubar",
        :password_confirmation => "fubar" }
      assert_match(/Your password has been changed/i, flash[:notice])
      assert_equal users(:johan), User.authenticate(users(:johan).email, "fubar")
    end 

    should "be able to update password, even if user created his account with openid" do
      user = users(:johan)
      user.update_attribute(:crypted_password, nil)
      put :update_password, :id => user.to_param, :user => {
        :password => "fubar",
        :password_confirmation => "fubar" }
      assert_redirected_to user_path(user)
      assert_match(/Your password has been changed/i, flash[:notice])
      assert_equal users(:johan), User.authenticate(users(:johan).email, "fubar")
    end
  end

end
