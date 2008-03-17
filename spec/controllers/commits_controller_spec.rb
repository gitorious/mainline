require File.dirname(__FILE__) + '/../spec_helper'

describe CommitsController do  
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
      response.should redirect_to(project_repository_log_path(@project, @repository, "somebranch"))
    end
    
    it "redirects if repository doens't have any commits" do
      @repository.should_receive(:has_commits?).and_return(false)
      get :index, :project_id => @project.slug, :repository_id => @repository.name
      response.should be_redirect
      flash[:notice].should match(/repository doesn't have any commits yet/)
    end
  end

  describe "#show" do    
    before(:each) do
      @commit_mock = stub("commit", :id => 1)
      @diff_mock = mock("diff mock")
      @commit_mock.should_receive(:diffs).and_return(@diff_mock)
      @git.should_receive(:commit).with("a"*40).and_return(@commit_mock)
    end
    
    def do_get(opts={})
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40}.merge(opts)
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
end
