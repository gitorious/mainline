require File.dirname(__FILE__) + '/../spec_helper'

describe BrowseController do
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
    def do_get(opts = {})
      get :index, {:project_id => @project.slug, 
        :repository_id => @repository.name, :page => nil, :head => "master"}.merge(opts)
    end
    
    it "GETs page 1 successfully" do
      @git.should_receive(:commits).with("master", 30, 0).and_return(mock("logentries"))
      do_get
    end
    
    it "GETs page 3 successfully" do
      @git.should_receive(:commits).with("master", 30, 60).and_return(mock("logentries"))
      do_get(:page => 3)
    end
    
    it "GETs the commits successfully" do
      commits = mock("logentries")
      @git.should_receive(:commits).with("master", 30, 0).and_return(commits)
      do_get
      response.should be_success
      assigns[:git].should == @git
      assigns[:commits].should == commits
    end
    
    it "redirects to the master head, if not params[:head] given" do
      head = mock("a branch")
      head.stub!(:name).and_return("somebranch")
      @repository.should_receive(:head_candidate).and_return(head)
      
      do_get(:head => nil)
      response.should redirect_to(project_repository_log_path(@project, @repository, "somebranch"))
    end
  end
  
  describe "#tree" do
    it "GETs successfully" do
      tree_mock = mock("tree")
      tree_mock.stub!(:id).and_return("123")
      @commit_mock = mock("commit")
      @commit_mock.stub!(:tree).and_return(tree_mock)
      @git.should_receive(:commit).with("a"*40).and_return(@commit_mock)
      @git.should_receive(:tree).with(tree_mock.id, ["foo/bar/"]).and_return(tree_mock)
      get :tree, :project_id => @project.slug, 
        :repository_id => @repository.name, :sha => "a"*40, :path => ["foo", "bar"]
        
      response.should be_success
      assigns[:git].should == @git
      assigns[:tree].should == tree_mock
    end
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.should_receive(:commit).with("a"*40).and_return(nil)
      get :tree, :project_id => @project.slug, 
        :repository_id => @repository.name, :sha => "a"*40, :path => ["foo"]
      
      response.should redirect_to(project_repository_tree_path(@project, @repository, "HEAD", ["foo"]))
    end
  end
  
  describe "#commit" do    
    before(:each) do
      @commit_mock = mock("commit")
      @diff_mock = mock("diff mock")
      @commit_mock.should_receive(:diffs).and_return(@diff_mock)
      @git.should_receive(:commit).with("a"*40).and_return(@commit_mock)
    end
    
    def do_get(opts={})
      get :commit, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40}.merge(opts)
    end
    
    it "gets the commit data" do
      do_get
      response.should be_success
      assigns[:git].should == @git
      assigns[:commit].should == @commit_mock
      assigns[:diffs].should == @diff_mock
    end
    
    it "gets the comments for the commit" do
      do_get
      assigns[:comment_count].should == 0
    end
    
    it "defaults to 'inline' diffmode" do
      do_get
      assigns[:diffmode].should == "inline"
    end
    
    it "sets sidebyside diffmode" do
      do_get(:diffmode => "sidebyside")
      assigns[:diffmode].should == "sidebyside"
    end
  end
  
  describe "#diff" do
    it "diffs the sha's provided" do
      diff_mock = mock("diff")
      @git.should_receive(:diff).with("a"*40, "b"*40).and_return(diff_mock)
      
      get :diff, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40, 
          :other_sha => "b"*40}
      
      response.should be_success
      assigns[:git].should == @git
      assigns[:diff].should == diff_mock
    end
  end
  
  describe "#blob" do
    it "gets the blob data for the sha provided" do
      blob_mock = mock("blob")
      blob_mock.stub!(:contents).and_return([blob_mock]) #meh
      blob_mock.stub!(:data).and_return("blob contents")
      commit_stub = mock("commit")
      commit_stub.stub!(:id).and_return("a"*40)
      commit_stub.stub!(:tree).and_return(commit_stub)
      @git.should_receive(:commit).and_return(commit_stub)
      @git.should_receive(:tree).and_return(blob_mock)
      
      get :blob, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40, :path => []}
      
      response.should be_success
      assigns[:git].should == @git
      assigns[:blob].should == blob_mock
    end 
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.should_receive(:commit).with("a"*40).and_return(nil)
      get :blob, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40, :path => ["foo.rb"]}
      
      response.should redirect_to(project_repository_blob_path(@project, @repository, "HEAD", ["foo.rb"]))
    end   
  end
  
  describe "#raw" do
    it "gets the blob data from the sha and renders it as text/plain" do
      blob_mock = mock("blob")
      blob_mock.stub!(:contents).and_return([blob_mock]) #meh
      blob_mock.should_receive(:data).and_return("blabla")
      blob_mock.should_receive(:size).and_return(200.kilobytes)
      blob_mock.should_receive(:mime_type).and_return("text/plain")
      commit_stub = mock("commit")
      commit_stub.stub!(:id).and_return("a"*40)
      commit_stub.stub!(:tree).and_return(commit_stub)
      @git.should_receive(:commit).and_return(commit_stub)
      @git.should_receive(:tree).and_return(blob_mock)
      
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40, :path => []}
      
      response.should be_success
      assigns[:git].should == @git
      assigns[:blob].should == blob_mock
      response.body.should == "blabla"
      response.content_type.should == "text/plain"
    end
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.should_receive(:commit).with("a"*40).and_return(nil)
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40, :path => ["foo.rb"]}
      
      response.should redirect_to(project_repository_raw_blob_path(@project, @repository, "HEAD", ["foo.rb"]))
    end
    
    it "redirects if blob is too big" do
      blob_mock = mock("blob")
      blob_mock.stub!(:contents).and_return([blob_mock]) #meh
      blob_mock.should_receive(:size).and_return(501.kilobytes)
      commit_stub = mock("commit")
      commit_stub.stub!(:id).and_return("a"*40)
      commit_stub.stub!(:tree).and_return(commit_stub)
      @git.should_receive(:commit).and_return(commit_stub)
      @git.should_receive(:tree).and_return(blob_mock)
      
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40, :path => []}
          
      response.should redirect_to(project_repository_path(@project, @repository))
    end
  end
  
  describe "#archive" do
    def do_get(opts = {})
      get :archive, {:project_id => @project.slug, 
        :repository_id => @repository.name}.merge(opts)
    end
    
    it "does not archive the source tree if the sha is invalid" do
      @git.should_receive(:commit).with(nil).and_return(nil)
      do_get
      response.should_not be_success
    end
    
    it "archives the source tree" do
      do_get(:sha => "a"*40)
      response.should be_success
      
      response.headers["type"].should == "application/x-gzip"
      response.headers["Content-Transfer-Encoding"].should == "binary"
    end
  end

end
