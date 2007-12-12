require File.dirname(__FILE__) + '/../spec_helper'

describe RepositoriesController, "show" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  def do_get(repos)
    get :show, :project_id => @project.slug, :id => repos.name
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

describe RepositoriesController, "show as XML" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  def do_get(repos)
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :show, :project_id => @project.slug, :id => repos.name
  end
  
  it "GET projects/1/repositories/1.xml is successful" do
    do_get @project.repositories.first
    response.should be_success
    response.body.should == @project.repositories.first.to_xml
  end
end

describe RepositoriesController, "new" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
  end
  
  def do_get()
    get :new, :project_id => @project.slug
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
    authorize_as :johan
    @project = projects(:johans)
  end
  
  def do_post(data)
    @request.env["HTTP_ACCEPT"] = "application/xml"
    post :create, :project_id => @project.slug, :repository => data
  end
  
  it "should require authorization" do
    authorize_as(nil)
    do_post(:name => "foo")
    response.code.to_i.should == 401
  end
  
  it "POST projects/1/repositories/create is successful" do
    do_post(:name => "foo")
    response.code.to_i.should == 201    
  end
end

describe RepositoriesController, "copy" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_get()
    get :copy, :project_id => @project.slug, :id => @repository.name
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_get
    response.should redirect_to(new_sessions_path)
  end
  
  it "GET projects/1/repositories/3/clone is successful" do
    do_get
    response.should be_success
    assigns[:repository_to_clone].should == @repository
    assigns[:repository].should be_instance_of(Repository)
  end
end

describe RepositoriesController, "clone" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_post(opts={})
    post(:create_copy, :project_id => @project.slug, :id => @repository.name,
      :repository => opts)
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_post
    response.should redirect_to(new_sessions_path)
  end
  
  it "post projects/1/repositories/3/create_copy is successful" do
    do_post(:name => "foo-clone")
    response.should be_redirect
  end
end

describe RepositoriesController, "clone as XML" do
  
  before(:each) do
    authorize_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_post(opts={})
    @request.env["HTTP_ACCEPT"] = "application/xml"
    post(:create_copy, :project_id => @project.slug, :id => @repository.name,
      :repository => opts)
  end
  
  it "should require login" do
    authorize_as(nil)
    do_post(:name => "foo")
    response.code.to_i.should == 401
  end
  
  it "post projects/1/repositories/3/create_copy is successful" do
    do_post(:name => "foo-clone")
    response.code.to_i.should == 201
  end
end

describe RepositoriesController, "writable_by" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_get(options={})
    post(:writable_by, {:project_id => @project.slug, :id => @repository.name,
      :username => "johan"}.merge(options))
  end
  
  it "should not require login" do
    session[:user_id] = nil
    do_get :username => "johan"
    response.should_not redirect_to(new_sessions_path)
  end
  
  it "get projects/1/repositories/3/writable_by?username=johan is true" do
    do_get :username => "johan"
    response.should be_success
    response.body.should == "true"
  end
  
  it "get projects/1/repositories/2/writable_by?username=johan is false" do
    do_get :username => "johan", :project_id => projects(:moes).slug, 
      :id => projects(:moes).repositories.first.name
    response.should be_success
    response.body.should == "false"
  end
  
  it "get projects/1/repositories/2/writable_by?username=nonexistinguser is false" do
    do_get :username => "nonexistinguser"
    response.should be_success
    response.body.should == "false"
  end
end