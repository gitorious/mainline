require File.dirname(__FILE__) + '/../spec_helper'

describe LogsController do

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
  end

  describe "#show" do
    def do_get(opts = {})
      get :show, {:project_id => @project.slug, 
        :repository_id => @repository.name, :page => nil, :id => "master"}.merge(opts)
    end

    it "GETs page 1 successfully" do
      @git.should_receive(:commits).with("master", 30, 0).and_return([mock("commits")])
      do_get
    end

    it "GETs page 3 successfully" do
      @git.should_receive(:commits).with("master", 30, 60).and_return([mock("commits")])
      do_get(:page => 3)
    end

    it "GETs the commits successfully" do
      commits = [mock("commits")]
      @git.should_receive(:commits).with("master", 30, 0).and_return(commits)
      do_get
      response.should be_success
      assigns[:git].should == @git
      assigns[:commits].should == commits
    end
  end

end
