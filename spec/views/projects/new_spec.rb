require File.dirname(__FILE__) + '/../../spec_helper'

describe "projects/new.rhtml" do
  before(:each) do
    @project = Project.new
  end
  
  it "should render a form for creating a new user" do
    assigns[:project] = @project
    render "projects/new"    
    response.should have_tag("h1", /create/i)
    response.should have_tag("form[action=/projects]") do
      with_tag("input#project_title")
      with_tag("textarea#project_description")
    end
  end
  
  it "should render error messages for an invalid project" do
    errors = mock("ActiveRecord::Errors")
    errors.should_receive(:full_messages).and_return(["owies"])
    errors.stub!(:count).and_return(1)
    @project.stub!(:errors).and_return(errors)
    assigns[:project] = @project
    
    render "projects/new"
    response.should have_tag("ul>li", "owies")
  end
end