require File.dirname(__FILE__) + '/../spec_helper'

describe EventsController do
  before(:each) do
    @project = projects(:johans)
    @repository = repositories(:johans)
  end
  
  describe "#index" do
    def do_get
      get :index
    end
    
    it "shows news" do
      projects(:johans).create_event(Action::CREATE_PROJECT, @repository, users(:johan), "", "")
      do_get
      response.should be_success
    end
  end
end

