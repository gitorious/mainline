require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  before(:each) do
    @user = User.new
  end
  
  it "should have valid associations" do
    @user.should have_valid_associations
  end
  
  it "should create a valid user" do
    proc {
      user = create_user
      user.new_record?.should be(false)
    }.should change(User, :count)
  end
    
  it "should require a login attribute on the user object" do
    proc{
      u = create_user(:login => "")
      u.errors_on(:login).should_not == nil
    }.should_not change(User, :count)
  end
  
  it "requires a username without spaces" do
    proc{
      u = create_user(:login => "joe schmoe")
      u.should have(1).errors_on(:login)
    }.should_not change(User, :count)
  end
  
  it "should require password" do
    proc{
      u = create_user(:password => nil)
      u.errors.on(:password).should_not be_empty
    }.should_not change(User, :count)
  end
  
  it "should require password confirmation" do
    proc{
      u = create_user(:password_confirmation => nil)
      u.errors.on(:password_confirmation).should_not be_empty
    }.should_not change(User, :count)
  end
  
  it "should require email" do
    proc{
      u = create_user(:email => nil)
      u.errors.on(:email).should_not be_empty
    }.should_not change(User, :count)
  end
  
  it "should require an email that looks emailish" do
    proc{
      u = create_user(:email => "kernel.wtf")
      u.errors.on(:email).should_not be_empty
    }.should_not change(User, :count)
  end
  
  it "should accept co.uk and the like" do
    proc{
      u = create_user(:email => "ker+nel.w-t-f@foo-bar.co.uk")
      u.errors.should be_empty
    }.should change(User, :count)
  end
  
  it "should reset password" do
    users(:johan).update_attributes(:password => "newpass", :password_confirmation => "newpass")
    User.authenticate("johan@johansorensen.com", "newpass").should == users(:johan)
  end
  
  it "should not rehash the password" do
    users(:johan).update_attributes(:email => 'johan2@js.com')
    User.authenticate("johan2@js.com", "test").should == users(:johan)
  end
  
  it "should authenticate user" do
    User.authenticate("johan@johansorensen.com", "test").should == users(:johan)
  end
  
  it "should set remember token" do
    users(:johan).remember_me
    users(:johan).remember_token.should_not be(nil)
    users(:johan).remember_token_expires_at.should_not be(nil)
  end
  
  it "should unset remember token" do
    users(:johan).remember_me
    users(:johan).remember_token.should_not be(nil)
    users(:johan).forget_me
    users(:johan).remember_token.should be(nil)
  end 
  
  it "should remember user for one week" do
    before = 1.week.from_now.utc
    users(:johan).remember_me_for 1.week
    after = 1.week.from_now.utc
    users(:johan).remember_token.should_not be(nil)
    users(:johan).remember_token_expires_at.should_not be(nil)
    users(:johan).remember_token_expires_at.between?(before, after).should be(true)
  end 
  
  it "should remember me until one week later" do
    time = 1.week.from_now.utc
    users(:johan).remember_me_until time
    users(:johan).remember_token.should_not be(nil)
    users(:johan).remember_token_expires_at.should_not be(nil)
    users(:johan).remember_token_expires_at.should == time
  end 
  
  it "should remember me default two weeks" do
    before = 2.weeks.from_now.utc
    users(:johan).remember_me
    after = 2.weeks.from_now.utc
    users(:johan).remember_token.should_not be(nil)
    users(:johan).remember_token_expires_at.should_not be(nil)
    users(:johan).remember_token_expires_at.between?(before, after).should be(true)
  end
  
  it "knows if a user has write access to a repository" do
    u = users(:johan)
    repo = repositories(:johans)
    u.can_write_to?(repo).should == true
    u.can_write_to?(repositories(:moes)).should == false
    
    u.committerships.destroy_all
    u.reload
    u.can_write_to?(repo).should == false
    u.can_write_to?(repositories(:moes)).should == false
  end
  
  it "has the login as to_param" do
    users(:johan).to_param.should == users(:johan).login
  end
  
  it "finds a user by login or raises" do
    User.find_by_login!(users(:johan).login).should == users(:johan)
    proc{
      User.find_by_login!("asdasdasd")
    }.should raise_error(ActiveRecord::RecordNotFound)
  end
  
  protected
    def create_user(options = {})
      u = User.new({ 
        :email => 'quire@example.com', 
        :password => 'quire', 
        :password_confirmation => 'quire' 
      }.merge(options))
      u.login = options[:login] || "quire"
      u.save
      u
    end
end
