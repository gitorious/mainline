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
      u = create_user(:login => nil)
      u.should have(2).errors_on(:login)
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
  
  it "should reset password" do
    users(:johan).update_attributes(:password => "newpass", :password_confirmation => "newpass")
    User.authenticate("johan", "newpass").should == users(:johan)
  end
  
  it "should not rehash the password" do
    users(:johan).update_attributes(:login => 'johan2')
    User.authenticate("johan2", "test").should == users(:johan)
  end
  
  it "should authenticate user" do
    User.authenticate("johan", "test").should == users(:johan)
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
  
  it "should have a valid ssh key" do
    u = users(:johan)
    u.ssh_key = ""
    u.should_not be_valid
    u.ssh_key = "foo bar@baz"
    u.should_not be_valid
    
    u.ssh_key = nil
    u.should be_valid    
    u.ssh_key = "ssh-rsa asdasdasdasd bar@baz"
    u.should be_valid
  end
  
  protected
    def create_user(options = {})
      User.create({ 
        :login => 'quire', 
        :email => 'quire@example.com', 
        :password => 'quire', 
        :password_confirmation => 'quire' 
      }.merge(options))
    end
end
