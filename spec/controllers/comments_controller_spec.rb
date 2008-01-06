require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsController do

  before(:each) do
    @project = projects(:johans)
    @repository = repositories(:johans)
  end
  
  describe "#index" do
  
    def do_get
      get :index, :project_id => @project.slug, 
        :repository_id => @repository.name
    end
    
    it "scopes to project.repositories" do
      do_get
      response.should be_success
      assigns[:comments].should_not include(comments(:moes_repos))
    end
  end
  
  describe "#new" do
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
      assigns[:comment].repository.should == @repository
    end
  end
  
  describe "#create" do
    
    def do_post(opts = {})
      get :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :comment => opts
    end
    
    it "requires login" do
      session[:user_id] = nil
      do_post
      response.should redirect_to(new_sessions_path)
    end
    
    it "scopes to the repository" do
      login_as :johan
      do_post :body => "blabla"
      assigns[:comment].repository.should == @repository
    end
    
    it "assigns the comment to the current_user" do
      login_as :johan
      do_post :body => "blabla"
      assigns[:comment].user.should == users(:johan)
    end
    
    it "creates the record on successful data" do
      login_as :johan
      proc {
        do_post :body => "moo"
        response.should redirect_to(project_repository_comments_path(@project, @repository))
        flash[:success].should match(/your comment was added/i)
      }.should change(Comment, :count)
    end
    
    it "it re-renders on invalid data" do
      login_as :johan
      do_post :body => nil
      response.should be_success
      response.should render_template("comments/new")
    end
    
  end
end

