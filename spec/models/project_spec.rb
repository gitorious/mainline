require File.dirname(__FILE__) + '/../spec_helper'

describe Project do
  before(:each) do
    @project = Project.new(:name => "foo project")
  end

  it "should have valid associations" do
    @project.should have_valid_associations
  end
  
  it "should have a name to be valid" do
    project = Project.new
    project.should_not be_valid
    project.name = "foo"
    project.should be_valid
  end
end
