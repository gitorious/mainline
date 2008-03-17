require File.dirname(__FILE__) + '/../spec_helper'

describe SearchesController do

  describe "#show" do
    it "searches for the given query" do
      searcher = mock("ultrasphinx search")
      Ultrasphinx::Search.should_receive(:new).with({
        :query => "foo", :page => 1
      }).and_return(searcher)
      searcher.should_receive(:run)
      searcher.should_receive(:results).and_return(results = mock("results"))
      
      get :show, :q => "foo"
      assigns["search"].should == searcher
      assigns["results"].should == results
    end
    
    it "doesnt search if there's no :q param" do
      Ultrasphinx::Search.should_not_receive(:new)
      get :show, :q => ""
      assigns["search"].should == nil
      assigns["results"].should == nil
    end
  end

end
