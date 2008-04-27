require File.dirname(__FILE__) + '/../spec_helper'

describe SiteController do

  describe "#index" do    
    it "GETs sucessfully" do
      get :index
      response.should be_success
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
    
    it "get a list of the current_users repositories, that's not mainline" do
      get :dashboard
      assigns[:repositories].should == [repositories(:johans_moe_clone)]
    end
  end

end
