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
    User.authenticate(users(:johan).email, "fubar").should == users(:johan)
  end

end
