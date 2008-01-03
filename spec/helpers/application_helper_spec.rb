require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper do
  
  it "renders a message if an object is not ready?" do
    repos = repositories(:johans)
    build_notice_for(repos).should include("This repository is being created")
  end
  
  it "renders block if object is ready" do
    obj = mock("any given object")
    obj.stub!(:ready?).and_return(true)
    render_if_ready(obj) do
      "moo"
    end.should == "moo"
  end
  
  it "renders block if object is ready" do
    obj = mock("any given object")
    obj.stub!(:ready?).and_return(false)
    _erbout = "" # damn you RSpec!
    render_if_ready(obj) do
      "moo"
    end
    _erbout.should_not == "moo"
    _erbout.should match(/is being created/)
  end
  
end
