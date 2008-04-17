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
      users(:johan).create_event(Action::CREATE_PROJECT, @repository, "", "")
      do_get
      response.should be_success
    end
  end
end

