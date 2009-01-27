#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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

require File.dirname(__FILE__) + '/../spec_helper'

describe AccountsController do

  before(:each) do
    login_as :johan
  end
  
  it "GET /account should require login" do
    session[:user_id] = nil
    get :show
    response.should be_redirect
    response.should redirect_to(new_sessions_path)
  end
  
  it "GET /account is successful" do
    get :show
    response.should be_success
  end
  
  it "GET /account/edit is successful" do
    get :edit
    response.should be_success
  end
  
  it "PUT /account/create with valid data is successful" do
    put :update, :user => {:password => "fubar", :password_confirmation => "fubar"}
    flash[:notice].should_not be(nil)
    response.should redirect_to(account_path)
  end
  
  it 'PUT /account with confirmation of terms of service should redirect to show' do
    u = users(:johan)
    u.update_attributes(:aasm_state => 'pending')
    put :update, :user => {:eula => '1'}
    flash[:notice].should_not be(nil)
    response.should redirect_to(account_path)
  end
  
  it "GET /account/password is a-ok" do
    get :password
    response.should be_success
    assigns[:user].should == users(:johan)
  end
  
  it "PUT /account/update_password updates password if old one matches" do
    put :update_password, :user => {
      :current_password => "test", 
      :password => "fubar",
      :password_confirmation => "fubar" }
    response.should redirect_to(account_path)
    flash[:notice].should match(/Your password has been changed/i)
    User.authenticate(users(:johan).email, "fubar").should == users(:johan)
  end
  
  it "PUT /account/update_password does not update password if old one is wrong" do
    put :update_password, :user => {
      :current_password => "notthecurrentpassword", 
      :password => "fubar",
      :password_confirmation => "fubar" }
    flash[:notice].should == nil
    flash[:error].should match(/doesn't seem to match/)
    response.should render_template("accounts/password")
    User.authenticate(users(:johan).email, "test").should == users(:johan)
    User.authenticate(users(:johan).email, "fubar").should == nil
  end
  
  it "should be able to update password, even if user is openid enabled" do
    user = users(:johan)
    user.update_attribute(:identity_url, "http://johan.someprovider.com/")
    put :update_password, :user => {
      :current_password => "test", 
      :password => "fubar",
      :password_confirmation => "fubar" }
    flash[:notice].should match(/Your password has been changed/i)
    User.authenticate(users(:johan).email, "fubar").should == users(:johan)
  end 
 
  it "should be able to update password, even if user created his account with openid" do
    user = users(:johan)
    user.update_attribute(:crypted_password, nil)
    put :update_password, :user => {
      :password => "fubar",
      :password_confirmation => "fubar" }
    flash[:notice].should match(/Your password has been changed/i)
    User.authenticate(users(:johan).email, "fubar").should == users(:johan)
  end

end
