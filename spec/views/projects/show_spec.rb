require File.dirname(__FILE__) + '/../../spec_helper'

describe "projects(show.rhtml)" do
  before(:each) do
    @project = projects(:johans_project)
    assigns[:project] = @project
  end
  
  it "should render the project title" do
    render "projects/show.rhtml"
    response.should have_tag("h1", @project.title)
  end
  
  it "should render the project description" do
    render "projects/show.rhtml"
    response.should have_tag("p", @project.description)
  end
end