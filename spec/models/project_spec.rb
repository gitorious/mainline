require File.dirname(__FILE__) + '/../spec_helper'

describe Project do
  
  def create_project(options={})
    Project.new({
      :title => "foo project", 
      :slug => "foo", 
      :user => users(:johan)
    }.merge(options))
  end
  
  it "should have valid associations" do
    create_project.should have_valid_associations
  end
  
  it "should have a title to be valid" do
    project = create_project(:title => nil)
    project.should_not be_valid
    project.title = "foo"
    project.should be_valid
  end
  
  it "should have a slug to be valid" do
    project = create_project(:slug => nil)
    project.should_not be_valid
  end
  
  it "should have an alhanumeric slug" do
    project = create_project(:slug => "asd asd")
    project.valid?
    project.should_not be_valid
  end
  
  it "should downcase the slug before validation" do
    project = create_project(:slug => "FOO")
    project.valid?
    project.slug.should == "foo"
  end
  
end
