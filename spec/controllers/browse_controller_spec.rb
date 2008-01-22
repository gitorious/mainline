require File.dirname(__FILE__) + '/../spec_helper'

describe BrowseController do
  before(:each) do
    login_as :johan
    @project = projects(:johans)
    @repository = @project.repositories.first
    
    Project.should_receive(:find_by_slug!).with(@project.slug) \
      .and_return(@project)
    @project.repositories.should_receive(:find_by_name!) \
      .with(@repository.name).and_return(@repository)
    @repository.stub!(:has_commits?).and_return(true)
    
    @git_mock = mock("Git mock", :null_object => true)
    Gitorious::Gitto.should_receive(:new) \
      .with(@repository.full_repository_path) \
      .and_return(@git_mock)
  end
  
  describe "index" do

    def do_get
      get :index, :project_id => @project.slug, :repository_id => @repository.name
    end
    
    it "GETs successfully" do
      do_get
      flash[:notice].should == nil
      response.should be_success
    end
    
    it "fetches the specified log entries" do
      @git_mock.should_receive(:log).with(BrowseController::LOGS_PER_PAGE).and_return(commits=mock("logentrues"))
      do_get
      assigns[:commits].should == commits
    end    
    
    it "assigns the tags for easy lookup" do
      @git_mock.should_receive(:log).with(BrowseController::LOGS_PER_PAGE).and_return(commits=mock("logentrues"))
      do_get
      assigns[:tags_per_sha].should == {:write => "me"}
    end
  end

end
