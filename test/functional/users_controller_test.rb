# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
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
  should_enforce_ssl_for(:delete, :avatar)
  should_enforce_ssl_for(:get, :activate)
  should_enforce_ssl_for(:get, :edit)
  should_enforce_ssl_for(:get, :feed)
  should_enforce_ssl_for(:get, :forgot_password)
  should_enforce_ssl_for(:get, :new)
  should_enforce_ssl_for(:get, :openid_build)
  should_enforce_ssl_for(:get, :password)
  should_enforce_ssl_for(:get, :pending_activation)
  should_enforce_ssl_for(:get, :reset_password, :token => "a1bda21bd3b332bda")
  should_enforce_ssl_for(:get, :show)
  should_enforce_ssl_for(:get, :watchlist)
  should_enforce_ssl_for(:post, :create)
  should_enforce_ssl_for(:post, :forgot_password_create)
  should_enforce_ssl_for(:post, :openid_create)
  should_enforce_ssl_for(:put, :reset_password)
  should_enforce_ssl_for(:put, :update)
  should_enforce_ssl_for(:put, :update_password)

  context "http methods" do
    setup { login_as :johan }

    should_verify_method :post, :create
    should_verify_method :post, :forgot_password_create
    should_verify_method :put, :update, :id => "johan"
    should_verify_method :put, :update_password, :id => "johan"
    should_verify_method :delete, :avatar, :id => "johan"
  end

  should_render_in_global_context

  should "show pending activation" do
    get :pending_activation
    assert_response :success
  end

  should "redirect from pending activation if logged in" do
    login_as :johan
    get :pending_activation
    assert_response :redirect
  end

  should "activate user" do
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

    should "does not recognize controller collection actions as repositories" do
      assert_recognizes({
        :controller => "users", :action => "forgot_password"
      }, {:path => "/users/forgot_password", :method => :get})
    end

    should "does not recognize controller member actions as repositories" do
      assert_recognizes({
        :controller => "users", :action => "activate", :activation_code => "123"
      }, {:path => "/users/activate/123", :method => :get})
    end
  end

  def create_user(options = {})
    post :create, :user => { :login => 'quire', :email => 'quire@example.com',
      :password => 'quire', :password_confirmation => 'quire',
      :terms_of_use => '1' }.merge(options)
  end

  should "allow signups" do
    assert_difference("User.count") do
      create_user
      assert_redirected_to :action => "pending_activation"
    end
  end

  should "require login on signup" do
    assert_no_difference("User.count") do
      create_user(:login => nil)
      assert_not_nil assigns(:user).errors.on(:login)
      assert_template("users/new")
    end
  end

  should "require password on signup" do
    assert_no_difference("User.count") do
      create_user(:password => nil)
      assert !assigns(:user).errors.on(:password).empty?
      assert_template(("users/new"))
    end
  end

  should "require password confirmation on signup" do
    assert_no_difference("User.count") do
      create_user(:password_confirmation => nil)
      assert !assigns(:user).errors.on(:password_confirmation).empty?, 'empty? should be false'
      assert_template(("users/new"))
    end
  end

  should "require email on signup" do
    assert_no_difference("User.count") do
      create_user(:email => nil)
      assert !assigns(:user).errors.on(:email).empty?, 'empty? should be false'
      assert_template(("users/new"))
    end
  end

  should 'require acceptance of end user license agreement' do
    assert_no_difference("User.count") do
      create_user(:terms_of_use => nil)
    end
  end

  should "be successful with valid data" do
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

  should "recognizes sub-resource routing with dots in it" do
    assert_recognizes({
      :controller => "licenses",
      :action => "edit",
      :user_id => "j.s"
    }, "/users/j.s/license/edit")
    assert_recognizes({
      :controller => "licenses",
      :action => "edit",
      :user_id => "j.s"
    }, "/~j.s/license/edit")
  end

  should "recognizes activate routes" do
    assert_recognizes({
      :controller => "users",
      :action => "activate",
      :activation_code => "abc123",
    }, "/users/activate/abc123")
  end

  context "GET show" do
    should "#show sets atom feed autodiscovery" do
      user = users(:johan)
      get :show, :id => user.login
      assert_equal feed_user_path(user, :format => :atom), assigns(:atom_auto_discovery_url)
    end

    should "not display inactive users" do
      user = users(:johan)
      user.update_attribute(:activation_code, "123")
      assert !user.activated?

      get :show, :id => user.to_param
      assert_response :redirect
      assert_match(/is not public/, flash[:notice])
    end

    context "paginating user events" do
      setup { @params = { :id => users(:johan).login } }
      should_scope_pagination_to(:show, Event)
    end
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

  context "#reset" do
    setup do
      @user = users(:johan)
      @user.update_attribute(:password_key, "s3kr1t")
    end

    should "redirect if the token is invalid" do
      get :reset_password, :token => "invalid"
      assert_response :redirect
      assert_redirected_to forgot_password_users_path
      assert_not_nil flash[:error]
    end

    should "render the form if the token is valid" do
      get :reset_password, :token => "s3kr1t"
      assert_response :success
      assert_equal @user, assigns(:user)
      assert_nil flash[:error]
    end

    should "re-render if password confirmation does not match" do
      put :reset_password, :token => "s3kr1t", :user => {
        :password => "qwertyasdf",
        :password_confirmation => "asdf"
      }
      assert_response :success
      assert !assigns(:user).valid?
      assert_nil User.authenticate(@user.email, "qwertyasdf")
    end

    should "update the password" do
      put :reset_password, :token => "s3kr1t", :user => {
        :password => "qwertyasdf",
        :password_confirmation => "qwertyasdf"
      }
      assert_response :redirect
      assert_redirected_to new_sessions_path
      assert User.authenticate(@user.email, "qwertyasdf")
      assert_match(/Password updated/i, flash[:success])
    end
  end

  context "#forgot_password_create" do
    should "redirects to forgot_password if nothing was found" do
      post :forgot_password_create, :user => {:email => "xxx"}
      assert_redirected_to(forgot_password_users_path)
      assert_match(/invalid email/i, flash[:error])
    end

    should "sends a new password if email was found" do
      u = users(:johan)
      User.expects(:generate_reset_password_key).returns("secret")
      Mailer.expects(:deliver_forgotten_password).with(u, "secret")
      post :forgot_password_create, :user => {:email => u.email}
      assert_redirected_to(root_path)
      assert_match(/A password confirmation link has been sent/, flash[:success])
    end

    should 'notify non-activated users that they need to activate their accounts before resetting the password' do
      user = users(:johan)
      user.expects(:activated?).returns(false)
      User.expects(:find_by_email).returns(user)
      post :forgot_password_create, :user => {:email => user.email}
      assert_redirected_to forgot_password_users_path
      assert_match(/activated yet/, flash[:error])
    end
  end

  context "in Private Mode" do
    setup do
      GitoriousConfig['public_mode'] = false
    end

    teardown do
      GitoriousConfig['public_mode'] = true
    end

    should "activate user" do
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

    should "GET /users/johan" do
      get :show, :id => users(:johan).to_param
      assert_redirected_to(root_path)
      assert_match(/Action requires login/, flash[:error])
    end

    should "GET /users/new" do
      get :new
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

    should "render the field for favorite notifications" do
      get :edit, :id => users(:johan).to_param

      assert_select "input#user_default_favorite_notifications"
    end

    should "PUT /users/create with valid data is successful" do
      put :update, :id => users(:johan).to_param, :user => {
        :password => "fubar",
        :password_confirmation => "fubar"
      }
      assert !flash[:success].nil?
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
      assert_match(/Your password has been changed/i, flash[:success])
      assert_equal user, User.authenticate(user.email, "fubar")
    end

    should "PUT /users/johan/update_password does not update password if old one is wrong" do
      put :update_password, :id => users(:johan).to_param, :user => {
        :current_password => "notthecurrentpassword",
        :password => "fubar",
        :password_confirmation => "fubar" }
      assert_nil flash[:notice]
      assert_match(/does not seem to match/, flash[:error])
      assert_template("users/password")
      assert_equal users(:johan), User.authenticate(users(:johan).email, "test")
      assert_nil User.authenticate(users(:johan).email, "fubar")
    end

    should "PUT /users/johan/update should not update password" do
      user = users(:johan)
      put :update, :id => user.to_param, :user => {
        :password => "fubar",
        :password_confirmation => "fubar" }

      assert_nil User.authenticate(user.email, "fubar")
      assert_equal user, User.authenticate(user.email, "test")
    end

    should "be able to update password, even if user is openid enabled" do
      user = users(:johan)
      user.update_attribute(:identity_url, "http://johan.someprovider.com/")
      put :update_password, :id => user.to_param, :user => {
        :current_password => "test",
        :password => "fubar",
        :password_confirmation => "fubar" }
      assert_match(/Your password has been changed/i, flash[:success])
      assert_equal users(:johan), User.authenticate(users(:johan).email, "fubar")
    end

    should "be able to update password, even if user created his account with openid" do
      user = users(:johan)
      user.update_attribute(:crypted_password, nil)
      put :update_password, :id => user.to_param, :user => {
        :password => "fubar",
        :password_confirmation => "fubar" }
      assert_redirected_to user_path(user)
      assert_match(/Your password has been changed/i, flash[:success])
      assert_equal users(:johan), User.authenticate(users(:johan).email, "fubar")
    end

    should "be able to delete his avatar" do
      user = users(:johan)
      user.update_attribute(:avatar_file_name, "foo.png")
      assert user.avatar?
      delete :avatar, :id => user.to_param
      assert_redirected_to user_path(user)
      assert !user.reload.avatar?
    end
  end

  context "Viewing ones own favorites" do
    setup {
      login_as(:johan)
      @user = users(:johan)
      @merge_request = merge_requests(:moes_to_johans)
      @user.favorites.create(:watchable => @merge_request)
      @project = projects(:johans)
      @user.favorites.create(:watchable => @project)
    }

    should "render all" do
      get :show, :id => @user.login
      assert_response :success
    end
  end

  context "Watchlist" do
    setup { @user = users(:johan) }
    teardown { Rails.cache.clear }

    should "render activities watched by the user" do
      get :watchlist, :id => @user.to_param, :format => "atom"
      assert_response :success
    end

    should "not fail rendering feed when an event's user is nil" do
      repository = repositories(:johans)
      repository.project.events.create!({
        :action => Action::DELETE_TAG,
        :target => repository,
        :user => nil,
        :user_email => "marius@gitorious.com",
        :body => "Bla bla",
        :data => "A string of some kind"
      })

      get :watchlist, :id => @user.to_param, :format => "atom"

      assert_response :success
    end
  end

  context "Message privacy" do
    setup {@username = :johan}

    should "not expose messages unless current user" do
      login_as :moe
      get :show, :id => @username.to_s
      assert_nil assigns(:messages)
    end

    should "expose messages if current user" do
      login_as @username
      get :show, :id => @username.to_s
      assert_not_nil assigns(:messages)
    end
  end

  context "Creation from OpenID" do
    setup do
      @valid_session_options = {:openid_url => 'http://moe.example/', :openid_nickname => 'schmoe'}
    end

    should "deny access unless OpenID information is present in the session" do
      get :openid_build
      assert_response :redirect
    end

    should "build a user from the OpenID information and render the form" do
      get :openid_build, {}, @valid_session_options
      user = assigns(:user)
      assert_not_nil user
      assert_equal 'http://moe.example/', user.identity_url
      assert_response :success
    end

    should "render the form unless all required fields have been filled" do
      post :openid_create, {:user => {}}, @valid_session_options
      user = assigns(:user)
      assert_response :success
      assert_template 'users/openid_build'
    end

    should "create a user with the provided credentials and openid url on success" do
      assert_incremented_by(ActionMailer::Base.deliveries, :size, 1) do
        post :openid_create, {:user => {
          :fullname => 'Moe Schmoe',
          :email => 'moe@schmoe.example',
          :login => 'schmoe',
          :terms_of_use => '1'
          }
        }, @valid_session_options
      end

      user = assigns(:user)
      assert user.activated?
      assert user.terms_accepted?
      assert_nil session[:openid_url]
      assert_equal user, @controller.send(:current_user)
      assert_response :redirect
    end

    should "redirect to the dashboard on successful creation" do
      post :openid_create, { :user => {
          :fullname => 'Moe Schmoe',
          :email => 'moe@schmoe.example',
          :login => 'schmoe',
          :terms_of_use => '1'
        }
      }, @valid_session_options

      assert_redirected_to "/"
    end
  end
end
