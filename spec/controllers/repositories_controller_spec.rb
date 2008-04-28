require File.dirname(__FILE__) + '/../spec_helper'

describe RepositoriesController, "index" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  it "gets all the projects repositories" do
    get :index, :project_id => @project.slug
    response.should be_success
    assigns(:repositories).should == @project.repositories
  end
end


describe RepositoriesController, "show" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  def do_get(repos)
    get :show, :project_id => @project.slug, :id => repos.name
  end
  
  it "GET projects/1/repositories/1 is successful" do
    repo = @project.repositories.first
    repo.stub!(:git).and_return(mock("git mock", :null_object => true))
    do_get repo
    response.should be_success
  end
  
  it "scopes GET :show to the project_id" do
    repo = repositories(:moes)
    repo.stub!(:git).and_return(mock("git mock", :null_object => true))
    do_get repo
    response.code.to_i.should == 404
  end
  
  it "counts the number of merge requests" do
    repo = @project.repositories.first
    repo.stub!(:git).and_return(mock("git mock", :null_object => true))
    do_get repo
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
    repo = @project.repositories.first
    repo.stub!(:has_commits?).and_return(false)
    repo.stub!(:git).and_return(mock("git mock", :null_object => true))
    do_get repo
    response.should be_success
    response.body.should == repo.to_xml
  end
end

describe RepositoriesController, "new" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_get()
    get :new, :project_id => @project.slug, :id => @repository.name
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_get
    response.should redirect_to(new_sessions_path)
  end
  
  it "GET projects/1/repositories/3/new is successful" do
    Project.should_receive(:find_by_slug!).with(@project.slug).and_return(@project)
    @repository.stub!(:has_commits?).and_return(true)
    @project.repositories.should_receive(:find_by_name!).with(@repository.name).and_return(@repository)
    do_get
    flash[:error].should == nil
    response.should be_success
    assigns[:repository_to_clone].should == @repository
    assigns[:repository].should be_instance_of(Repository)
    assigns[:repository].name.should == "johans-clone"
  end
  
  it "redirects to new_account_key_path if no keys on user" do
    users(:johan).ssh_keys.destroy_all
    login_as :johan
    do_get
    response.should redirect_to(new_account_key_path)
  end
  
  it "redirects with a flash if repos can't be cloned" do
    login_as :johan
    Project.should_receive(:find_by_slug!).with(@project.slug).and_return(@project)
    @repository.stub!(:has_commits?).and_return(false)
    @project.repositories.should_receive(:find_by_name!).with(@repository.name).and_return(@repository)
    do_get
    response.should redirect_to(project_repository_path(@project, @repository))
    flash[:error].should match(/can't clone an empty/i)
  end
end

describe RepositoriesController, "create" do
  
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_post(opts={})
    post(:create, :project_id => @project.slug, :id => @repository.name,
      :repository => opts)
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_post
    response.should redirect_to(new_sessions_path)
  end
  
  it "post projects/1/repositories/3/create_copy is successful" do
    Project.should_receive(:find_by_slug!).with(@project.slug).and_return(@project)
    @repository.stub!(:has_commits?).and_return(true)
    @project.repositories.should_receive(:find_by_name!).with(@repository.name).and_return(@repository)
    do_post(:name => "foo-clone")
    response.should be_redirect
  end
  
  it "redirects to new_account_key_path if no keys on user" do
    users(:johan).ssh_keys.destroy_all
    login_as :johan
    do_post
    response.should redirect_to(new_account_key_path)
  end
  
  it "redirects with a flash if repos can't be cloned" do
    login_as :johan
    Project.should_receive(:find_by_slug!).with(@project.slug).and_return(@project)
    @repository.stub!(:has_commits?).and_return(false)
    @project.repositories.should_receive(:find_by_name!).with(@repository.name).and_return(@repository)
    do_post(:name => "foobar")
    response.should redirect_to(project_repository_path(@project, @repository))
    flash[:error].should match(/can't clone an empty/i)
  end
end

describe RepositoriesController, "create as XML" do
  
  before(:each) do
    authorize_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def do_post(opts={})
    @request.env["HTTP_ACCEPT"] = "application/xml"
    post(:create, :project_id => @project.slug, :id => @repository.name,
      :repository => opts)
  end
  
  it "should require login" do
    authorize_as(nil)
    do_post(:name => "foo")
    response.code.to_i.should == 401
  end
  
  it "post projects/1/repositories/3/create_copy is successful" do
    Project.should_receive(:find_by_slug!).with(@project.slug).and_return(@project)
    @repository.stub!(:has_commits?).and_return(true)
    @project.repositories.should_receive(:find_by_name!).with(@repository.name).and_return(@repository)
    do_post(:name => "foo-clone")
    response.code.to_i.should == 201
  end
  
  it "renders text if repos can't be cloned" do
    Project.should_receive(:find_by_slug!).with(@project.slug).and_return(@project)
    @repository.stub!(:has_commits?).and_return(false)
    @project.repositories.should_receive(:find_by_name!).with(@repository.name).and_return(@repository)
    do_post(:name => "foobar")
    response.code.to_i.should == 422
    response.body.should match(/can't clone an empty/i)
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

describe RepositoriesController, "destroy" do
  
  before(:each) do
    @project = projects(:johans)
  end
  
  def do_delete(repos)
    delete :destroy, :project_id => @project.slug, :id => repos.name
  end
  
  it "should require login" do
    session[:user_id] = nil
    do_delete(@project.repositories.first)
    response.should redirect_to(new_sessions_path)
  end
  
  it "can only be deleted by the owner" do
    login_as :johan
    @project.repositories.last.update_attribute(:user_id, users(:moe).id)
    do_delete(@project.repositories.last)
    response.should redirect_to(project_path(@project))
    flash[:error].should == "You're not the owner of this repository"
  end
  
  it "the owner can delete his own repos" do
    login_as :johan
    @project.repositories.last.update_attribute(:user_id, users(:johan))
    do_delete(@project.repositories.last)
    response.should redirect_to(project_path(@project))
    flash[:error].should == nil
    flash[:notice].should == "The repository was deleted"
  end
  
end