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
