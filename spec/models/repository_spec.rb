require File.dirname(__FILE__) + '/../spec_helper'

describe Repository do
  before(:each) do
    @repository = Repository.new({
      :name => "foo",
      :project => projects(:johans),
      :user => users(:johan)
    })
  end
  
  it "should have valid associations" do
    @repository.should have_valid_associations
  end

  it "should have a name to be valid" do
    @repository.name = nil
    @repository.should_not be_valid
  end
  
  it "should only accept names with alphanum characters in it" do
    @repository.name = "foo bar"
    @repository.should_not be_valid
    
    @repository.name = "foo!bar"
    @repository.should_not be_valid
    
    @repository.name = "foobar"
    @repository.should be_valid
    
    @repository.name = "foo42"
    @repository.should be_valid
  end
  
  it "sets itself as mainline if it's the first repository for a project" do
    projects(:johans).repositories.destroy_all
    projects(:johans).repositories.reload.size.should == 0
    @repository.save
    @repository.mainline?.should == true
  end
  
  it "doesnt set itself as mainline if there's more than one repos" do
    @repository.save
    @repository.mainline?.should == false
  end
  
  it "has a gitdir name" do
    @repository.gitdir.should == "foo.git"
  end
  
  it "has a push url" do
    @repository.push_url.should == "git@keysersource.org:foo.git"
  end
  
  it "has a clone url" do
    @repository.clone_url.should == "git://keysersource.org/foo.git"
  end
  
  it "should assign the creator as a comitter on create" do 
    @repository.save!
    @repository.reload
    @repository.committers.should include(users(:johan))
  end
end
