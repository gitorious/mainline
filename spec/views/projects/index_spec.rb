require File.dirname(__FILE__) + '/../../spec_helper'

describe "projects/index.rhtml" do
  before(:each) do
    @project = mock_model(Project, {:title => "foo"})
    @projects = [@project]
  end
  
  it "should render a list of users" do
    assigns[:projects] = @projects
    render "projects/index.rhtml"
    
    response.should have_tag("ul") do 
      with_tag("li", @project.title)
    end
  end
  
  it "should have a link to create a new project" do
    assigns[:projects] = [] # dont care about those here
    render "projects/index.rhtml"
    
    response.should have_tag("a[href=#{new_project_path}]", "New project")
  end
end