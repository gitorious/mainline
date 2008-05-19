require File.dirname(__FILE__) + '/../spec_helper'

describe TreesController do
  
  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
    @repository.stub!(:full_repository_path).and_return(repo_path)

    Project.should_receive(:find_by_slug!).with(@project.slug) \
      .and_return(@project)
    @project.repositories.should_receive(:find_by_name!) \
      .with(@repository.name).and_return(@repository)
    @repository.stub!(:has_commits?).and_return(true)

    @git = mock("Grit mock", :null_object => true)
    @repository.stub!(:git).and_return(@git)
    @head = mock("master branch")
    @head.stub!(:name).and_return("master")
    @repository.stub!(:head_candidate).and_return(@head)
  end
  
  describe "#index" do
    it "redirects to the master head, if not :id given" do
      head = mock("a branch")
      head.stub!(:name).and_return("somebranch")
      @repository.should_receive(:head_candidate).and_return(head)

      get :index, :project_id => @project.slug, :repository_id => @repository.name
      response.should redirect_to(project_repository_tree_path(@project, @repository, "somebranch", []))
    end
  end
  
  describe "#show" do
    it "GETs successfully" do
      tree_mock = mock("tree")
      tree_mock.stub!(:id).and_return("123")
      @commit_mock = mock("commit")
      @commit_mock.stub!(:tree).and_return(tree_mock)
      @git.should_receive(:commit).with("a"*40).and_return(@commit_mock)
      @git.should_receive(:tree).with(tree_mock.id, ["foo/bar/"]).and_return(tree_mock)
      get :show, :project_id => @project.slug, 
        :repository_id => @repository.name, :id => "a"*40, :path => ["foo", "bar"]
        
      response.should be_success
      assigns[:git].should == @git
      assigns[:tree].should == tree_mock
    end
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.should_receive(:commit).with("a"*40).and_return(nil)
      get :show, :project_id => @project.slug, 
        :repository_id => @repository.name, :id => "a"*40, :path => ["foo"]
      
      response.should redirect_to(project_repository_tree_path(@project, @repository, "HEAD", ["foo"]))
    end
  end
  
  describe "#archive" do
    def do_get(opts = {})
      get :archive, {:project_id => @project.slug, 
        :repository_id => @repository.name}.merge(opts)
    end
    
    it "archives the source tree" do
      @git.should_receive(:commit).and_return(true)
      @git.should_receive(:archive_tar_gz).and_return("the data")
      do_get
      response.should be_success
      
      response.headers["type"].should == "application/x-gzip"
      response.headers["Content-Transfer-Encoding"].should == "binary"
    end
  end

end
