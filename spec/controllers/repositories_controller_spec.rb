require File.dirname(__FILE__) + '/../spec_helper'

describe RepositoriesController, "show" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  def do_get(repos)
    get :show, :project_id => @project, :id => repos.id
  end
  
  it "GET projects/1/repositories/1 is successful" do
    do_get @project.repositories.first
    response.should be_success
  end
  
  it "scopes GET :show to the project_id" do
    proc  {
      do_get repositories(:moes)
    }.should raise_error(ActiveRecord::RecordNotFound)
  end
end

describe RepositoriesController, "new" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
  end
  
  def do_get()
    get :new, :project_id => @project
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_get
    response.should redirect_to(new_sessions_path)
  end
  
  it "GET projects/1/repositories/new is successful" do
    do_get
    response.should be_success
  end
end

describe RepositoriesController, "create" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
  end
  
  def do_post(data)
    post :create, :project_id => @project, :repository => data
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_post :name => "foo"
    response.should redirect_to(new_sessions_path)
  end
  
  it "POST projects/1/repositories/create is successful" do
    do_post(:name => "foo")
    response.should be_redirect
  end
  
  it "sets the first repository as the main line one" do
    @project.repositories.destroy_all
    do_post(:name => "foo")
    response.should be_redirect
    @project.reload
    @project.repositories.first.mainline?.should == true
  end
end
