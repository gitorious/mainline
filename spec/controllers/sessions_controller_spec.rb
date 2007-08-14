require File.dirname(__FILE__) + '/../spec_helper'

describe SessionsController do
  
  def auth_token(token)
    CGI::Cookie.new('name' => 'auth_token', 'value' => token)
  end

  def cookie_for(user)
    auth_token users(user).remember_token
  end

  it "should login and redirect" do
    post :create, :login => "quentin", :password => "test"
    session[:user].should_not be(nil)
    response.should be_redirect
  end
    
  it "should fail login and not redirect" do
    post :create, :login => 'quentin', :password => 'bad password'
    session[:user].should be(nil)
    response.should be_success
  end
    
  it "should logout" do
    login_as :quentin
    get :destroy
    session[:user].should be(nil)
    response.should be_redirect
  end
  
  it "should remember me" do
    post :create, :login => 'quentin', :password => 'test', :remember_me => "1"
    response.cookies["auth_token"].should_not be(nil)
  end 
  
  it "should should not remember me" do
    post :create, :login => 'quentin', :password => 'test', :remember_me => "0"
    response.cookies["auth_token"].should be(nil)
  end 
    
  it "should delete token on logout" do
    login_as :quentin
    get :destroy
    response.cookies["auth_token"].should == []
  end
  
  it "should login with cookie" do
    users(:quentin).remember_me
    request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    controller.send(:logged_in?).should be(true)
  end
    
  it "should fail when trying to login with with expired cookie" do
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago.utc
    request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    controller.send(:logged_in?).should be(false)
  end
    
  it "should fail cookie login" do
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :new
    @controller.send(:logged_in?).should be(false)
  end
  
end
