require File.dirname(__FILE__) + '/../spec_helper'

describe Repository do
  before(:each) do
    @repository = Repository.new({
      :name => "foo",
      :project => projects(:johans_project),
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
end
