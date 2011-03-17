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

class AliasesControllerTest < ActionController::TestCase

  should_render_in_global_context

  def setup
    @user = users(:johan)
    @email = emails(:johans1)
    login_as :johan
  end

  should_enforce_ssl_for(:delete, :destroy)
  should_enforce_ssl_for(:get, :confirm)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :new)
  should_enforce_ssl_for(:post, :create)

  context "Listing all emails" do
    should "require login" do
      login_as nil
      get :index, :user_id => @user.to_param
      assert_redirected_to new_sessions_path
    end

    should "require current_user" do
      login_as :moe
      get :index, :user_id => @user.to_param
      assert_redirected_to user_path(users(:moe))
    end

    should "List the current users emails" do
      get :index, :user_id => @user.to_param
      assert_response :success
      assert_equal @user.email_aliases, assigns(:emails)
    end
  end

  context "GETting the new email page" do
    should "require login" do
      login_as nil
      get :new, :user_id => @user.to_param
      assert_redirected_to new_sessions_path
    end

    should "require current_user" do
      login_as :moe
      get :new, :user_id => @user.to_param
      assert_redirected_to user_path(users(:moe))
    end

    should "should be ok" do
      get :new, :user_id => @user.to_param
      assert_response :success
      assert_template "new"
      assert_equal @user, assigns(:user)
    end
  end

  context "POSTing to create a new email page" do
    should "require login" do
      login_as nil
      post :create, :user_id => @user.to_param, :email => {:address => "bob@example.com"}
      assert_redirected_to new_sessions_path
    end

    should "require current_user" do
      login_as :moe
      post :create, :user_id => @user.to_param, :email => {:address => "bob@example.com"}
      assert_redirected_to user_path(users(:moe))
    end

    should "create the email" do
      assert_difference("@user.email_aliases.count") do
        post :create, :user_id => @user.to_param, :email => {:address => "bob@example.com"}
      end
      assert_response :redirect
      assert_redirected_to user_aliases_path(@user)
      assert_match(/receive an email asking you to confirm.+bob@example\.com/, flash[:success])
    end

    should "re-render the form on invalid data" do
      assert_no_difference("@user.email_aliases.count") do
        post :create, :user_id => @user.to_param, :email => {:address => "bob"}
      end
      assert_response :success
      assert_template "new"
    end
  end

  context "DELETE an email" do
    should "require login" do
      login_as nil
      delete :destroy, :user_id => @user.to_param, :id => @email.to_param
      assert_redirected_to new_sessions_path
    end

    should "require current_user" do
      login_as :moe
      delete :destroy, :user_id => @user.to_param, :id => @email.to_param
      assert_redirected_to user_path(users(:moe))
    end

    should "destroys the email" do
      assert_difference("@user.reload.email_aliases.count", -1) do
        delete :destroy, :user_id => @user.to_param, :id => @email.to_param
        assert_response :redirect
      end
      assert_equal "Email alias deleted", flash[:success]
      assert_redirected_to user_aliases_path(@user)
    end
  end

  context "Email confirmation" do
    setup do
      @email = Email.new(:address => "foo@bar.com")
      @email.user = users(:johan)
      @email.save!
      assert @email.pending?
    end

    should "should not confirm the email if the confirmation_code does not match" do
      login_as :johan
      get :confirm, :user_id => users(:johan).to_param, :id => "wrongcode"
      assert_response :redirect
      assert_redirected_to user_path(users(:johan))
      assert_match(/is incorrect/, flash[:error])
      assert @email.reload.pending?
    end

    should "should not confirm the email if the user is not right" do
      login_as :moe
      get :confirm, :user_id => users(:johan).to_param, :id => @email.confirmation_code
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
      assert_nil flash[:success]
      assert @email.reload.pending?
    end

    should "should confirm the email if everything is ok" do
      login_as :johan
      get :confirm, :user_id => users(:johan).to_param, :id => @email.confirmation_code
      assert_response :redirect
      assert_redirected_to user_aliases_path(users(:johan))
      assert_nil flash[:error]
      assert_match(/is now confirmed as belonging to you/, flash[:success])
      assert @email.reload.confirmed?
    end
  end
end
