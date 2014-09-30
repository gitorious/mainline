# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

require "test_helper"

class UsersControllerTest < ActionController::TestCase
  should_render_in_global_context

  def setup
    setup_ssl_from_config
  end

  should "render signup form" do
    get :new
    assert_response :success
  end

  should "disallow registration form if registrations are disabled" do
    Gitorious::Configuration.override("enable_registrations" => false) do
      get :new
      assert_response 403
    end
  end

  should "disallow registration if registrations are disabled" do
    Gitorious::Configuration.override("enable_registrations" => false) do
      post(:create, :user => {
          :login => "quire",
          :email => "quire@example.com",
          :password => "quire",
          :password_confirmation => "quire",
          :terms_of_use => "1"
        })

      assert_response 403
    end
  end

  should "register user" do
    assert_difference("User.count") do
      create_user
      assert_redirected_to :controller => "user_activations", :action => "show"
    end
  end

  should "reject registration when form is incomplete" do
    assert_no_difference("User.count") do
      create_user(:login => nil)
      assert_template("users/new")
    end
  end

  context "GET show" do
    should "show the user" do
      get :show, :id => users(:johan).login
      assert_response 200
      assert_match users(:johan).login, response.body
    end

    should "not disclose user's email when not desired" do
      user = users(:johan)
      user.update_attribute(:public_email, false)

      get :show, :id => user.to_param

      assert_response :success
      assert_select "#sidebar ul li.email", 0
    end

    should "set atom feed autodiscovery" do
      user = users(:johan)
      get :show, :id => user.login
      assert_match user_feed_path(user, :format => :atom), response.body
    end

    should "redirect to feed for atom format" do
      user = users(:johan)

      get :show, :id => user.login, :format => :atom

      assert_redirected_to user_feed_path(user, :format => :atom)
    end

    should "not display inactive users" do
      user = users(:johan)
      user.update_attribute(:activation_code, "123")

      get :show, :id => user.to_param

      assert_response :redirect
      assert_match(/is not public/, flash[:notice])
    end

    context "paginating user events" do
      setup { @params = { :id => users(:johan).login } }
      should_scope_pagination_to(:show, Event)
    end

    context "Viewing ones own favorites" do
      setup do
        login_as(:johan)
        @user = users(:johan)
        merge_request = merge_requests(:moes_to_johans)
        @user.favorites.create(:watchable => merge_request)
        project = projects(:johans)
        @user.favorites.create(:watchable => project)
      end

      should "render all" do
        get :show, :id => @user.to_param
        assert_response :success
      end
    end
  end

  context "in Private Mode" do
    setup do
      @test_settings = Gitorious::Configuration.prepend("public_mode" => false)
    end

    teardown do
      Gitorious::Configuration.prune(@test_settings)
    end

    should "GET /users/johan" do
      get :show, :id => users(:johan).to_param
      assert_redirected_to(new_sessions_path)
      assert_match(/Action requires login/, flash[:error])
    end

    should "GET /users/new" do
      get :new
      assert_redirected_to(new_sessions_path)
      assert_match(/Action requires login/, flash[:error])
    end
  end

  context "editing and updating user" do
    should "require current_user" do
      login_as :moe
      get :edit, :id => users(:johan).to_param
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end

    should "successfully edit when logged in" do
      login_as :johan
      get :edit, :id => users(:johan).to_param
      assert_response :success
    end

    should "render the field for favorite notifications" do
      login_as :johan
      get :edit, :id => users(:johan).to_param
      assert_select "input#user_default_favorite_notifications"
    end

    should "successfully edit user" do
      user = users(:johan)

      login_as :johan

      request.env['HTTP_REFERER'] = edit_user_path(user)

      put :update, :id => user.to_param, :user => { :fullname => "Zlorg" }

      refute flash[:success].nil?
      assert_redirected_to(edit_user_path(user))
    end

    should "not update password through edit" do
      user = users(:johan)

      put :update, :id => user.to_param, :user => {
        :password => "fubar",
        :password_confirmation => "fubar"
      }

      assert_nil User.authenticate(user.email, "fubar")
      assert_equal user, User.authenticate(user.email, "test")
    end
  end

  context "destroy" do
    should "require current_user" do
      get :destroy, :id => users(:johan).to_param
      assert_response :redirect
      assert_redirected_to new_sessions_path
    end

    should "require current_user to be the same as deleted user" do
      login_as :moe
      get :destroy, :id => users(:johan).to_param
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end

    should "be allowed if you don't own any projects or repos" do
      user = User.create!({
          :login => "thomas",
          :email => "thomas@openid.com",
          :identity_url => "http://myauth"
        })
      user.accept_terms
      login_as user

      get :destroy, :id => user.to_param

      assert_redirected_to root_path
      assert_match(/Account deleted/i, flash[:success])
      assert_nil User.find_by_login("thomas")
    end

    should "be prevented, with feedback message, if repos or projects present" do
      user = users(:moe) # has projects and repos
      login_as :moe

      get :destroy, :id => user.to_param

      assert_redirected_to user_path(user)
      assert_not_nil flash[:error]
      assert_not_nil User.find_by_login(user.login)
    end
  end

  context "With private repositories" do
    setup do
      @user = users(:johan)
      @project = @user.projects.first
      enable_private_repositories
    end

    should "filter projects" do
      get :show, :id => @user.to_param
      refute_match @project.title, response.body
    end

    should "show authorized projects" do
      login_as :johan
      get :show, :id => @user.to_param
      assert_match @project.title, response.body
    end

    should "filter commit repositories" do
      get :show, :id => @user.to_param
      refute_match @project.title, response.body
    end

    should "show authorized commit repositories" do
      login_as :johan
      get :show, :id => @user.to_param
      assert_match @project.title, response.body
    end

    should "filter events" do
      create_event(projects(:moes), @project.repositories.first)
      create_event(@project, @project.repositories.first)
      create_event(projects(:moes), projects(:moes).repositories.first)

      get :show, :id => @user.to_param
      assert_select ".gts-event", 1
    end
  end

  private
  def create_event(project, target)
    e = Event.new({ :target => target,
        :data => "master",
        :action => Action::CREATE_BRANCH })
    e.user = @user
    e.project = project
    e.save!
  end

  def create_user(options = {})
    post(:create, :user => {
        :login => "quire",
        :email => "quire@example.com",
        :password => "quire",
        :password_confirmation => "quire",
        :terms_of_use => "1"
      }.merge(options))
  end
end
