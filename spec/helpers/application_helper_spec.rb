require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper do
  
  it "renders build notice for an object if it responds tor ready?" do
    repos = repositories(:johans)
    repos.ready = true
    render_build_notice_for?(projects(:johans)).should == false
    render_build_notice_for?(repos).should == false
    repos.ready = false
    render_build_notice_for?(repos).should == true
  end
  
  it "renders a message if an object is not ready?" do
    repos = repositories(:johans)    
    repos.ready = true
    render_build_notice_for(repos).should == nil
    
    repos.ready = false
    render_build_notice_for(repos).should include("being created")
  end
  
end
