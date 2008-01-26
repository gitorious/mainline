require File.dirname(__FILE__) + '/../spec_helper'

describe SiteController do

  describe "#index" do    
    it "GETs sucessfully" do
      get :index
      response.should be_success
    end
    
    it "gets the tag list" do
      get :index
      assigns[:tags].should == Project.tag_counts
    end
    
    it "gets a list of the most recent projects" do
      get :index
      assigns[:projects].should == Project.find(:all, :limit => 5, :order => "id desc")
    end
  end
  
  describe "#dashboard" do
    before(:each) do
      login_as :johan
    end
    it "GETs successfully" do
      get :dashboard
      response.should be_success
      response.should render_template("site/dashboard")
    end
    
    it "requires login" do
      login_as nil
      get :dashboard
      response.should redirect_to(new_sessions_path)
    end
    
    it "get a list of the current_users projects" do
      get :dashboard
      assigns[:projects].should == [*projects(:johans)]
    end
    
    it "gets a list of recent comments from users projects" do
      get :dashboard
      assigns[:recent_comments].should == comments(:johans_repos, :johans_repos2)
    end
    
    it "gets a list of all the clones made of current_users repositories" do
      get :dashboard
      assigns[:repository_clones].should == [*repositories(:johans2)]
    end
  end

end
