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
  
  it "should have a unique slug to be valid" do
    p1 = create_project
    p1.save!
    p2 = create_project(:slug => "FOO")
    p2.should_not be_valid
    p2.should have(1).error_on(:slug)
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
  
  it "creates an initial repository for itself" do
    project = create_project
    project.save
    project.repositories.should_not == []
    project.repositories.first.name.should == project.slug
    project.repositories.first.user.should == project.user
    project.user.can_write_to?(project.repositories.first).should == true
  end
  
end
