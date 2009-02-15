# encoding: utf-8
#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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

class AccountsControllerTest < ActionController::TestCase
  
  def setup
    login_as :johan
  end
  
  should "GET /account should require login" do
    session[:user_id] = nil
    get :show
    assert_response :redirect
    assert_redirected_to new_sessions_path
  end
  
  should "GET /account is successful" do
    get :show
    assert_response :success
  end
  
  should "GET /account/edit is successful" do
    get :edit
    assert_response :success
  end
  
  should "PUT /account/create with valid data is successful" do
    put :update, :user => {:password => "fubar", :password_confirmation => "fubar"}
    assert !flash[:notice].nil?
    assert_redirected_to(account_path)
  end
  
 should "PUT /account with confirmation of terms of service should redirect to show" do
    u = users(:johan)
    u.update_attributes(:aasm_state => 'pending')
    put :update, :user => {:eula => '1'}
    assert !flash[:notice].nil?
    assert_redirected_to(account_path)
  end
  
  should "GET /account/password is a-ok" do
    get :password
    assert_response :success
    assert_equal users(:johan), assigns(:user)
  end
  
  should "PUT /account/update_password updates password if old one matches" do
    put :update_password, :user => {
      :current_password => "test", 
      :password => "fubar",
      :password_confirmation => "fubar" }
    assert_redirected_to(account_path)
    assert_match(/Your password has been changed/i, flash[:notice])
    assert_equal users(:johan), User.authenticate(users(:johan).email, "fubar")
  end
  
  should "PUT /account/update_password does not update password if old one is wrong" do
    put :update_password, :user => {
      :current_password => "notthecurrentpassword", 
      :password => "fubar",
      :password_confirmation => "fubar" }
    assert_nil flash[:notice]
    assert_match(/doesn't seem to match/, flash[:error])
    assert_template("accounts/password")
    assert_equal users(:johan), User.authenticate(users(:johan).email, "test")
    assert_nil User.authenticate(users(:johan).email, "fubar")
  end
  
  should " be able to update password, even if user is openid enabled" do
    user = users(:johan)
    user.update_attribute(:identity_url, "http://johan.someprovider.com/")
    put :update_password, :user => {
      :current_password => "test", 
      :password => "fubar",
      :password_confirmation => "fubar" }
    assert_match(/Your password has been changed/i, flash[:notice])
    assert_equal users(:johan), User.authenticate(users(:johan).email, "fubar")
  end 
 
  should " be able to update password, even if user created his account with openid" do
    user = users(:johan)
    user.update_attribute(:crypted_password, nil)
    put :update_password, :user => {
      :password => "fubar",
      :password_confirmation => "fubar" }
    assert_match(/Your password has been changed/i, flash[:notice])
    assert_equal users(:johan), User.authenticate(users(:johan).email, "fubar")
  end

end
