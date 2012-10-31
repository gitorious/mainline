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

require "test_helper"

class LicensesControllerTest < ActionController::TestCase
  def setup
    setup_ssl_from_config
  end

  context "Accepting (current) end user license agreement" do
    setup do
      @user = users(:old_timer)
      login_as :old_timer
    end

    should "GET show redirect to edit with a flash" do
      get :show, :user_id => "zmalltalker"
      assert_response :redirect
      assert_match(/You need to accept the/, flash[:notice])
    end

    should "render the current license version if this has been accepted" do
      @user.accept_terms!
      get :edit, :user_id => "zmalltalker"
      assert_redirected_to :action => :show
    end

    should "ask the user to confirm a newer version if this has not been acccepted" do
      get :edit, :user_id => "zmalltalker"
      assert_response :success
    end

    should "require the user to accept the terms" do
      put :update, :user_id => "zmalltalker", :user => {}
      assert_redirected_to :action => :edit
    end

    should "change the current version when selected" do
      put :update, :user_id => "zmalltalker", :user => { :terms_of_use => "1" }
      assert_redirected_to :action => :show
      assert @user.reload.terms_accepted?
    end

    should "not change the current version if not selected" do
      put :update, :user_id => "zmalltalker", :user => {:terms_of_use => ""}
      assert !@user.reload.terms_accepted?
      assert_match(/You need to accept the/, flash[:error])
    end
  end
end
