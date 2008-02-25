require File.dirname(__FILE__) + '/../spec_helper'

describe MergeRequest do
  before(:each) do
    @merge_request = merge_requests(:moes_to_johans)
  end

  it "should have valid associations" do
    @merge_request.should have_valid_associations
  end
  
  it "requires a user to be valid" do
    @merge_request.user = nil
    @merge_request.should have(1).error_on(:user)
  end
  
  it "requires a source_repository to be valid" do
    @merge_request.source_repository = nil
    @merge_request.should have(1).error_on(:source_repository)
  end
  
  it "requires a target_repository to be valid" do
    @merge_request.target_repository = nil
    @merge_request.should have(1).error_on(:target_repository)
  end
end
