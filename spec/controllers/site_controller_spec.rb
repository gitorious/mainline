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

end
