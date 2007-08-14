require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  
  def create_user(options = {})
    post :create, :user => { :login => 'quire', :email => 'quire@example.com',
      :password => 'quire', :password_confirmation => 'quire' }.merge(options)
  end
  
  it "should allow signups" do
    proc{
      create_user
      response.should be_redirect
    }.should change(User, :count)
  end
  
  it "should require login on signup" do
    proc{
      create_user(:login => nil)
      assigns(:user).should have(2).errors_on(:login)
      response.should render_template("users/new")
    }.should_not change(User, :count)
  end
  
  it "should require password on signup" do
    proc{
      create_user(:password => nil)
      assigns(:user).errors.on(:password).should_not be_empty
      response.should render_template("users/new")
    }.should_not change(User, :count)
  end
  
  it "should require password confirmation on signup" do
    proc {
      create_user(:password_confirmation => nil)
      assigns(:user).errors.on(:password_confirmation).should_not be_empty
      response.should render_template("users/new")
    }.should_not change(User, :count)
  end
  
  it "should require email on signup" do
    proc{
      create_user(:email => nil)
      assigns(:user).errors.on(:email).should_not be_empty
      response.should render_template("users/new")
    }.should_not change(User, :count)
  end
    
  it "should activate user" do
    User.authenticate('aaron', 'test').should be(nil)
    get :activate, :activation_code => users(:aaron).activation_code
    response.should redirect_to '/'
    flash[:notice].should_not be(nil)
    User.authenticate('aaron', 'test').should == users(:aaron)
  end

end
