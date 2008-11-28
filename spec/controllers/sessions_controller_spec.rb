#--
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 August Lilleaas <augustlilleaas@gmail.com>
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
include OpenIdAuthentication

describe SessionsController do
  
  def auth_token(token)
    CGI::Cookie.new('name' => 'auth_token', 'value' => token)
  end

  def cookie_for(user)
    auth_token users(user).remember_token
  end

  it "should login and redirect" do
    controller.stub!(:using_open_id?).and_return(false)
    post :create, :email => "johan@johansorensen.com", :password => "test"
    session[:user_id].should_not be(nil)
    response.should be_redirect
  end
 
  it "should login with openid and redirect" do
    identity_url = "http://patcito.myopenid.com"
    controller.stub!(:using_open_id?).and_return(true)
    controller.stub!(:successful?).and_return(false)
    controller.stub!(:authenticate_with_open_id).and_yield(Result[:successful],identity_url,registration={'nickname'=>"patcito",'email'=>"patcito@gmail.com",'fullname'=>'Patrick Aljord'})
    post :create, :openid_url => identity_url
    session[:user_id].should_not be(nil)
    response.should be_redirect
  end
   
  it "should fail login and not redirect" do
    controller.stub!(:using_open_id?).and_return(false)
    post :create, :email => 'johan@johansorensen.com', :password => 'bad password'
    session[:user_id].should be(nil)
    response.should be_success
  end
    
  it "should logout" do
    login_as :johan
    get :destroy
    session[:user_id].should be(nil)
    response.should be_redirect
  end
  
  it "should remember me" do
    controller.stub!(:using_open_id?).and_return(false)
    post :create, :email => 'johan@johansorensen.com', :password => 'test', :remember_me => "1"
    response.cookies["auth_token"].should_not be(nil)
  end 
  
  it "should should not remember me" do
    controller.stub!(:using_open_id?).and_return(false)
    post :create, :email => 'johan@johansorensen.com', :password => 'test', :remember_me => "0"
    response.cookies["auth_token"].should be(nil)
  end 
    
  it "should delete token on logout" do
    login_as :johan
    get :destroy
    response.cookies["auth_token"].should == []
  end
  
  it "should login with cookie" do
    users(:johan).remember_me
    request.cookies["auth_token"] = cookie_for(:johan)
    get :new
    controller.send(:logged_in?).should be(true)
  end
    
  it "should fail when trying to login with with expired cookie" do
    users(:johan).remember_me
    users(:johan).update_attribute :remember_token_expires_at, 5.minutes.ago.utc
    request.cookies["auth_token"] = cookie_for(:johan)
    get :new
    controller.send(:logged_in?).should be(false)
  end
    
  it "should fail cookie login" do
    users(:johan).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :new
    @controller.send(:logged_in?).should be(false)
  end
  
  it "should set current user to the session user_id" do
    session[:user_id] = users(:johan).id
    get :new
    controller.send(:current_user).should == users(:johan)
  end
  
  it "should show flash when invalid credentials are passed" do
    controller.stub!(:using_open_id?).and_return(false)
    post :create, :email => "invalid", :password => "also invalid"
    # response.body.should have_tag("div.flash_message", /please try again/)
    # rspec.should test(flash.now)
  end
end
