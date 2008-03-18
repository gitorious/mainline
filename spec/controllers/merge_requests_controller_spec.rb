require File.dirname(__FILE__) + '/../spec_helper'

describe MergeRequestsController do
  
  before(:each) do
    @project = projects(:johans)
    @repository = repositories(:johans2)
    @mainline_repository = repositories(:johans)
    @merge_request = merge_requests(:moes_to_johans)
  end
  
  describe "#index (GET)" do
    def do_get
      get :index, :project_id => @project.slug, 
        :repository_id => @repository.name
    end    
    
    it "should not require login" do
      session[:user_id] = nil
      do_get
      response.should_not redirect_to(new_sessions_path)      
    end
    
    it "gets all the merge requests in the repository" do
      do_get
      assigns[:merge_requests].should == @repository.merge_requests
    end
    
    it "gets a comment count for" do
      do_get
      assigns[:comment_count].should == @repository.comments.count
    end
  end
  
  describe "#show (GET)" do
    def do_get
      get :show, :project_id => @project.slug, 
        :repository_id => repositories(:johans).name,
        :id => @merge_request.id
    end
    
    it "should not require login" do
      session[:user_id] = nil
      MergeRequest.should_receive(:find).and_return(@merge_request)
      [@merge_request.source_repository, @merge_request.target_repository].each do |r|
        r.stub!(:git).and_return(mock("Git", :null_object => true))
      end
      do_get
      response.should_not redirect_to(new_sessions_path)      
    end
    
    it "gets a list of the commits to be merged" do
      MergeRequest.should_receive(:find).and_return(@merge_request)
      commits = [mock("commit"), mock("commit")]
      
      target_repo = mock("target repo")
      @merge_request.target_repository.stub!(:git).and_return(target_repo)
      
      src_repo = mock("src repo")
      @merge_request.source_repository.stub!(:git).and_return(src_repo)
      
      target_repo.should_receive(:commit_deltas_from).with(src_repo, "master", "master").and_return(commits)
      
      do_get
      assigns[:commits].should == commits
    end
  end

  describe "#new (GET)" do
    def do_get
      get :new, :project_id => @project.slug, 
        :repository_id => @repository.name
    end
    
    it "requires login" do
      session[:user_id] = nil
      do_get
      response.should redirect_to(new_sessions_path)
    end
    
    it "is successfull" do
      login_as :johan
      do_get
      response.should be_success
    end
    
    it "assigns the new merge_requests' source_repository" do
      login_as :johan
      do_get
      assigns[:merge_request].source_repository.should == @repository
    end
    
    it "gets a list of possible target clones" do
      login_as :johan
      do_get
      assigns[:repositories].should == [repositories(:johans)]
    end
  end
  
  describe "#create (POST)" do
    def do_post(data={})
      post :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :merge_request => {
          :target_repository_id => repositories(:johans2).id,
        }.merge(data)
    end
    
    it "requires login" do
      session[:user_id] = nil
      do_post
      response.should redirect_to(new_sessions_path)
    end
    
    it "scopes to the source_repository" do
      login_as :johan
      do_post
      assigns[:merge_request].source_repository.should == @repository
    end
    
    it "scopes to the current_user" do
      login_as :johan
      do_post
      assigns[:merge_request].user.should == users(:johan)
    end
    
    it "creates the record on successful data" do
      login_as :johan
      proc {
        do_post
        response.should redirect_to(project_repository_path(@project, @repository))
        flash[:success].should match(/sent a merge request to "#{repositories(:johans2).name}"/i)
      }.should change(MergeRequest, :count)
    end
    
    it "it re-renders on invalid data, with the target repos list" do
      login_as :johan
      do_post :target_repository => nil
      response.should be_success
      response.should render_template("merge_requests/new")
      assigns[:repositories].should == [repositories(:johans)]
    end
  end
  
  describe "#edit (GET)" do
    def do_get
      get :edit, :project_id => @project.slug, 
        :repository_id => @mainline_repository.name,
        :id => @merge_request
    end
    
    it "requires login" do
      session[:user_id] = nil
      do_get
      response.should redirect_to(new_sessions_path)
    end
    
    it "requires ownership to edit" do
      login_as :moe
      do_get
      flash[:error].should match(/you're not the owner/i)
      response.should be_redirect
    end
    
    it "is successfull" do
      login_as :johan
      do_get
      response.should be_success
    end
    
    it "gets a list of possible target clones" do
      login_as :johan
      do_get
      assigns[:repositories].should == [@repository]
    end
  end
  
  describe "#update (PUT)" do
    def do_put(data={})
      put :update, :project_id => @project.slug, 
        :repository_id => @mainline_repository.name, 
        :id => @merge_request,
        :merge_request => {
          :target_repository_id => repositories(:johans2).id,
        }.merge(data)
    end
    
    it "requires login" do
      session[:user_id] = nil
      do_put
      response.should redirect_to(new_sessions_path)
    end
    
    it "requires ownership to update" do
      login_as :moe
      do_put
      flash[:error].should match(/you're not the owner/i)
      response.should be_redirect
    end
    
    it "scopes to the source_repository" do
      login_as :johan
      do_put
      assigns[:merge_request].source_repository.should == @repository
    end
    
    it "scopes to the current_user" do
      login_as :johan
      do_put
      assigns[:merge_request].user.should == users(:johan)
    end
    
    it "updates the record on successful data" do
      login_as :johan
      do_put :proposal => "hai, plz merge kthnkxbye"
      
      response.should redirect_to(project_repository_merge_request_path(@project, @mainline_repository, @merge_request))
      flash[:success].should match(/merge request was updated/i)
      @merge_request.reload.proposal.should == "hai, plz merge kthnkxbye"
    end
    
    it "it re-renders on invalid data, with the target repos list" do
      login_as :johan
      do_put :target_repository => nil
      response.should be_success
      response.should render_template("merge_requests/edit")
      assigns[:repositories].should == [@repository]
    end
    
    it "only allows the owner to update" do
      login_as :moe
      do_put
      proc {
        response.should redirect_to(project_repository_path(@project, @mainline_repository))
        flash[:success].should == nil
        flash[:error].should match(/You're not the owner of this merge request/i)
      }.should_not change(MergeRequest, :count)
    end
  end
  
  describe "#resolve (PUT)" do
    def do_put(data={})
      put :resolve, :project_id => @project.slug, 
        :repository_id => @mainline_repository.name, 
        :id => @merge_request,
        :merge_request => {
          :status => MergeRequest::STATUS_MERGED,
        }.merge(data)
    end
    
    it "requires login" do
      session[:user_id] = nil
      do_put
      response.should redirect_to(new_sessions_path)
    end
    
    it "requires ownership to resoble" do
      login_as :moe
      do_put
      flash[:error].should match(/you're not permitted/i)
      response.should be_redirect
    end
    
    it "updates the status" do
      login_as :johan
      do_put
      flash[:notice].should == "The merge request was marked as merged"
      response.should be_redirect
    end
  end
  
  describe "#destroy (DELETE)" do
    def do_delete
      delete :destroy, :project_id => @project.slug, 
        :repository_id => @mainline_repository.name, 
        :id => @merge_request
    end
    
    it "requires login" do
      session[:user_id] = nil
      do_delete
      response.should redirect_to(new_sessions_path)
    end
    
    it "scopes to the source_repository" do
      login_as :johan
      do_delete
      assigns[:merge_request].source_repository.should == @repository
    end
    
    it "deletes the record" do
      login_as :johan
      do_delete
      response.should redirect_to(project_repository_path(@project, @mainline_repository))
      flash[:success].should match(/merge request was retracted/i)
      MergeRequest.find_by_id(@merge_request.id).should == nil
    end
    
    it "only allows the owner to delete" do
      login_as :moe
      do_delete
      proc {
        response.should redirect_to(project_repository_path(@project, @mainline_repository))
        flash[:success].should == nil
        flash[:error].should match(/You're not the owner of this merge request/i)
      }.should_not change(MergeRequest, :count)
    end
  end

end
