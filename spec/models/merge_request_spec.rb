#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe MergeRequest do
  before(:each) do
    @merge_request = merge_requests(:moes_to_johans)
    commits = %w(9dbb89110fc45362fc4dc3f60d960381 6823e6622e1da9751c87380ff01a1db1 526fa6c0b3182116d8ca2dc80dedeafb 286e8afb9576366a2a43b12b94738f07).collect do |sha|
      m = mock
      m.stubs(:id).returns(sha)
      m
    end
    @merge_request.stubs(:commits_for_selection).returns(commits)
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
    @merge_request.target_repository.owner = groups(:team_thunderbird)
    @merge_request.resolvable_by?(users(:mike)).should == true # is commiter of mainline repos
    @merge_request.resolvable_by?(users(:moe)).should == false
  end
  
  it "counts open merge_requests" do
    mr = @merge_request.clone
    mr.status = MergeRequest::STATUS_REJECTED
    mr.save
    MergeRequest.count_open.should == 1
  end
  
  it "it defaults to master for the source_branch" do
    mr = MergeRequest.new
    mr.source_branch.should == "master"
    mr.source_branch = "foo"
    mr.source_branch.should == "foo"
  end
  
  it "it defaults to master for the target_branch" do
    mr = MergeRequest.new
    mr.target_branch.should == "master"
    mr.target_branch = "foo"
    mr.target_branch.should == "foo"
  end
  
  it "has a source_name" do
    @merge_request.source_branch = "foo"
    @merge_request.source_name.should == "#{@merge_request.source_repository.name}:foo"
  end
  
  it "has a target_name" do
    @merge_request.target_branch = "foo"
    @merge_request.target_name.should == "#{@merge_request.target_repository.name}:foo"
  end
  
  describe "with specific starting and ending commits" do
    before(:each) do
      @merge_request.ending_commit = '6823e6622e1da9751c87380ff01a1db1'
    end
    it "should suggest relevant commits to be merged" do
      assert_equal(4, @merge_request.commits_for_selection.size)
    end
    
    it "should know that it applies to specific commits" do
      assert_equal(2, @merge_request.commits_to_be_merged.size)
      assert_equal(%w(9dbb89110fc45362fc4dc3f60d960381 6823e6622e1da9751c87380ff01a1db1), @merge_request.commits_to_be_merged.collect(&:id))
    end
    
    it "should return the full set of commits if ending_commit or starting_commit don't exist" do
      @merge_request.ending_commit = '526fa6c0b3182116d8ca2dc80dedeafb'
      assert_equal(3, @merge_request.commits_to_be_merged.size)
    end
  end
end
