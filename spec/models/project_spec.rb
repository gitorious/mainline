require File.dirname(__FILE__) + '/../spec_helper'

describe Project do
  before(:each) do
    @project = Project.new(:title => "foo project")
  end

  it "should have valid associations" do
    @project.should have_valid_associations
  end
  
  it "should have a title to be valid" do
    project = Project.new
    project.should_not be_valid
    project.title = "foo"
    project.should be_valid
  end
end
