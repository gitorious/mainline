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
    repo.owner.group.add_member(users(:moe), Role.committer)
    users(:moe).can_write_to?(repo).should == true
    
  end
  
  it "should only have project repo as #repositories" do
    users(:johan).repositories.should_not include(repositories(:johans_wiki))
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
  
  it "generates some randomly password" do
    User.generate_random_password.should match(/\w+/)
    User.generate_random_password.length.should == 12
    User.generate_random_password(16).length.should == 16
    User.generate_random_password(5).length.should == 5
  end
  
  it "resets a password to something" do
    u = users(:johan)
    password = u.reset_password!
    User.authenticate(u.email, password).should_not be_nil
  end
  
  it "normalizes identity urls" do
    u = users(:johan)
    u.identity_url = "http://johan.someprovider.com"
    u.valid?.should be_true
    u.identity_url.should == "http://johan.someprovider.com/"
    
    u.identity_url = "http://johan.someprovider.com/me"
    u.valid?.should be_true
    u.identity_url.should == "http://johan.someprovider.com/me"
  end
  
  it "catches invalid identity_url" do
    u = users(:johan)
    u.identity_url = "€&/()"
    u.should have(1).errors_on(:identity_url)
  end
 
  it "should return that the user already has a password" do
    u = users(:johan)
    u.is_openid_only?.should == false
  end
  
  it "should return an grit actor object" do
    js = users(:johan)
    actor = js.to_grit_actor
    actor.should be_instance_of(Grit::Actor)
    actor.name.should == js.login
    actor.email.should == js.email
    js.fullname = "sonic the hedgehog"
    js.to_grit_actor.name.should == js.fullname
  end
  
  it 'should require acceptance of terms' do
    proc{
      u = create_user(:eula => nil)
      u.errors.on(:eula).should_not be_empty
    }.should_not change(User, :count)
  end
  
  it 'should initially be pending' do
    u = create_user
    u.should be_pending
  end
  
  it 'should have its state transformed when accepting the eula' do
    u = create_user
    u.eula = '1'
    u.should be_terms_accepted
  end
  
  it "should have many memberships" do
    users(:johan).memberships.should == [memberships(:johans_johan)]
    groups(:johans_team_thunderbird).add_member(users(:johan), Role.admin)
    users(:johan).memberships.count.should == 2
  end
  
  it "has many groups through the memberships" do
    groups(:johans_team_thunderbird).add_member(users(:johan), Role.admin)
    users(:johan).groups.should == groups(:johans_team_thunderbird, :johans_core)
  end
 
  protected
    def create_user(options = {})
      u = User.new({ 
        :email => 'quire@example.com', 
        :password => 'quire', 
        :password_confirmation => 'quire',
        :eula => '1'
      }.merge(options))
      u.login = options[:login] || "quire"
      u.save
      u
    end
end
