require File.dirname(__FILE__) + '/../spec_helper'

describe BrowseController do
  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
    
    Project.should_receive(:find_by_slug!).with(@project.slug) \
      .and_return(@project)
    @project.repositories.should_receive(:find_by_name!) \
      .with(@repository.name).and_return(@repository)
    @repository.stub!(:has_commits?).and_return(true)
    
    @gitto = mock("Gitto mock", :null_object => true)
    Gitorious::Gitto.should_receive(:new) \
      .with(@repository.full_repository_path) \
      .and_return(@gitto)
  end
  
  describe "#index" do
    def do_get
      get :index, :project_id => @project.slug, :repository_id => @repository.name
    end
    
    it "GETs successfully" do
      do_get
      flash[:notice].should == nil
      response.should be_success
    end
    
    it "fetches the specified log entries" do
      @gitto.should_receive(:log).with(BrowseController::LOGS_PER_PAGE) \
        .and_return(commits=mock("logentrues"))
      do_get
      assigns[:commits].should == commits
    end    
    
    it "assigns the tags for easy lookup" do
      @gitto.should_receive(:log).with(BrowseController::LOGS_PER_PAGE) \
        .and_return(mock("logentrues"))
      @gitto.should_receive(:tags_by_sha).and_return({"foo" => ["bar"]})
      do_get
      assigns[:tags_per_sha].should == {"foo" => ["bar"]}
    end
  end
  
  describe "#tree" do
    it "GETs successfully" do
      tree_mock = mock("gtree")
      @gitto.should_receive(:tree).and_return(tree_mock)
      get :tree, :project_id => @project.slug, 
        :repository_id => @repository.name, :sha => "a"*40
        
      response.should be_success
      assigns[:git].should == @gitto
      assigns[:tree].should == tree_mock
    end
  end
  
  describe "#commit" do    
    before(:each) do
      @commit_mock = mock("commit")
      @commit_mock.stub!(:sha).and_return("a"*40)
      @commit_mock.stub!(:parent).and_return(@commit_mock)
      @diff_mock = mock("diff")
      @gitto.should_receive(:diff).with(@commit_mock.parent.sha, 
        @commit_mock.sha).and_return(@diff_mock)
      @gitto.should_receive(:commit).with("a"*40).and_return(@commit_mock)
    end
    def do_get(opts={})
      get :commit, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40}.merge(opts)
    end
    it "gets the commit data" do
      do_get
      response.should be_success
      assigns[:git].should == @gitto
      assigns[:commit].should == @commit_mock
      assigns[:diff].should == @diff_mock
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
      @gitto.should_receive(:diff).with("a"*40, "b"*40).and_return(diff_mock)
      
      get :diff, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40, :other_sha => "b"*40}
      
      response.should be_success
      assigns[:git].should == @gitto
      assigns[:diff].should == diff_mock
    end
  end
  
  describe "#blob" do
    it "gets the blob data for the sha provided" do
      blob_mock = mock("blob")
      @gitto.should_receive(:blob).with("a"*40).and_return(blob_mock)
      
      get :blob, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40}
      
      response.should be_success
      assigns[:git].should == @gitto
      assigns[:blob].should == blob_mock
    end    
  end
  
  describe "#raw" do
    it "gets the blob data from the sha and renders it as text/plain" do
      blob_mock = mock("blob")
      blob_mock.stub!(:contents).and_return("blabla")
      @gitto.should_receive(:blob).with("a"*40).and_return(blob_mock)
      
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :sha => "a"*40}
      
      response.should be_success
      assigns[:git].should == @gitto
      assigns[:blob].should == blob_mock
      response.body.should == "blabla"
      response.content_type.should == "text/plain"
    end
  end
  
  describe "#log" do
    def do_get(opts = {})
      get :log, {:project_id => @project.slug, 
        :repository_id => @repository.name, :page => nil}.merge(opts)
    end
    
    it "GETs page 1 successfully" do
      @gitto.should_receive(:log).with(30, 0).and_return(mock("logentries"))
      do_get
    end
    
    it "GETs page 3 successfully" do
      @gitto.should_receive(:log).with(30, 60).and_return(mock("logentries"))
      do_get(:page => 3)
    end
    
    it "GETs the commits successfully" do
      commits = mock("logentries")
      @gitto.should_receive(:log).with(30, 0).and_return(commits)
      do_get
      response.should be_success
      assigns[:git].should == @gitto
      assigns[:commits].should == commits
    end
    
    it "assigns the tags for easy lookup" do
      @gitto.should_receive(:log).with(30, 0).and_return(mock("logentries"))
      @gitto.should_receive(:tags_by_sha).and_return({"foo" => ["bar"]})
      do_get
      assigns[:tags_per_sha].should == {"foo" => ["bar"]}
    end
  end

end
