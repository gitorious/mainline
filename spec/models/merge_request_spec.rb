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
  
  it "emails the owner of the target_repository on create" do
    Mailer.deliveries = []
    mr = @merge_request.clone
    mr.save
    Mailer.deliveries.should_not be_empty
  end
  
  it "has a merged? status" do
    @merge_request.status = MergeRequest::STATUS_MERGED
    @merge_request.merged?.should == true
  end
  
  it "has a rejected? status" do
    @merge_request.status = MergeRequest::STATUS_REJECTED
    @merge_request.rejected?.should == true
  end
  
  it "has a open? status" do
    @merge_request.status = MergeRequest::STATUS_OPEN
    @merge_request.open?.should == true
  end
  
  it "has a statuses class method" do
    MergeRequest.statuses["Open"].should == MergeRequest::STATUS_OPEN
    MergeRequest.statuses["Merged"].should == MergeRequest::STATUS_MERGED
    MergeRequest.statuses["Rejected"].should == MergeRequest::STATUS_REJECTED
  end
  
  it "has a status_string" do
    MergeRequest.statuses.each do |k,v|
      @merge_request.status = v
      @merge_request.status_string.should == k.downcase
    end
  end
  
  it "knows who can resolve itself" do
    @merge_request.resolvable_by?(users(:johan)).should == true # owns the mainline repos
    @merge_request.resolvable_by?(users(:moe)).should == false
  end
  
  it "counts open merge_requests" do
    mr = @merge_request.clone
    mr.status = MergeRequest::STATUS_REJECTED
    mr.save
    MergeRequest.count_open.should == 1
  end
end
