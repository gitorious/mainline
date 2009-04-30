# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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


require File.dirname(__FILE__) + '/../test_helper'

class MergeRequestTest < ActiveSupport::TestCase

  def setup
    @merge_request = merge_requests(:moes_to_johans)
    commits = %w(9dbb89110fc45362fc4dc3f60d960381 6823e6622e1da9751c87380ff01a1db1 526fa6c0b3182116d8ca2dc80dedeafb 286e8afb9576366a2a43b12b94738f07).collect do |sha|
      m = mock
      m.stubs(:id).returns(sha)
      m
    end
    @merge_request.stubs(:commits_for_selection).returns(commits)
    assert @merge_request.pending_acceptance_of_terms?
  end
  
  should_validate_presence_of :user, :source_repository, :target_repository, 
                              :ending_commit
  should_have_many :comments
  
  should "email all committers in the target_repository after the terms are accepted" do
    assert_incremented_by(Message, :count, 1) do
      mr = @merge_request.clone
      mr.target_repository = repositories(:johans2) # doesn't deliver messages to the actor
      mr.stubs(:valid_oauth_credentials?).returns(true)
      mr.stubs(:oauth_signoff_parameters).returns({})
      mr.save
      mr.terms_accepted
    end
  end
  
  should "has a merged? status" do
    @merge_request.status = MergeRequest::STATUS_MERGED
    assert @merge_request.merged?, '@merge_request.merged? should be true'
  end
  
  should "has a rejected? status" do
    @merge_request.status = MergeRequest::STATUS_REJECTED
    assert @merge_request.rejected?, '@merge_request.rejected? should be true'
  end
  
  should "has a open? status" do
    @merge_request.status = MergeRequest::STATUS_OPEN
    assert @merge_request.open?, '@merge_request.open? should be true'
  end
  
  should "has a statuses class method" do
    assert_equal MergeRequest::STATUS_PENDING_ACCEPTANCE_OF_TERMS, MergeRequest.statuses["Pending"]
    assert_equal MergeRequest::STATUS_OPEN, MergeRequest.statuses["Open"]
    assert_equal MergeRequest::STATUS_MERGED, MergeRequest.statuses["Merged"]
    assert_equal MergeRequest::STATUS_REJECTED, MergeRequest.statuses["Rejected"]
  end
  
  should "has a status_string" do
    MergeRequest.statuses.each do |k,v|
      @merge_request.status = v
      assert_equal k.downcase, @merge_request.status_string
    end
  end
  
  should "knows who can resolve itself" do
    assert @merge_request.resolvable_by?(users(:johan)), '@merge_request.resolvable_by?(users(:johan)) should be true'
    @merge_request.target_repository.committerships.create!(:committer => groups(:team_thunderbird))
    assert @merge_request.resolvable_by?(users(:mike)), '@merge_request.resolvable_by?(users(:mike)) should be true'
    assert !@merge_request.resolvable_by?(users(:moe)), '@merge_request.resolvable_by?(users(:moe)) should be false'
  end
  
  should "counts open merge_requests" do
    mr = @merge_request.clone
    mr.status = MergeRequest::STATUS_REJECTED
    mr.save
    assert_equal 1, MergeRequest.count_open
  end
  
  should 'have a transition from pending to open' do
    mr = @merge_request.clone
    assert mr.pending_acceptance_of_terms?
    @merge_request.oauth_consumer.valid_oauth_credentials=({:key => 'key', :secret => 'secret'})
    mr.stubs(:oauth_signoff_parameters).returns({})
    mr.terms_accepted
    assert mr.open?
    assert_equal 'valid_version_sha', mr.contribution_agreement_version
    assert_equal 'Thank you for your contribution', mr.contribution_notice
  end
  
  should 'not be set to open if OAuth validation fails' do
    mr = @merge_request.clone
    mr.oauth_token = "key"
    mr.oauth_secret = "invalid_secret"
    mr.oauth_consumer.valid_oauth_credentials=({:key => 'key', :secret => 'secret'})
    assert !mr.open?
  end
  
  should 'require signoff when target repository requires it' do
    mr = @merge_request.clone
    assert mr.acceptance_of_terms_required?
  end
  
  should 'not require signoff when target repository does not require so' do
    mr = MergeRequest.new(:source_repository => repositories(:johans), :target_repository => repositories(:johans2), :ending_commit => '00ffcc')
    assert !mr.acceptance_of_terms_required?
  end
  
  should "it defaults to master for the source_branch" do
    mr = MergeRequest.new
    assert_equal "master", mr.source_branch
    mr.source_branch = "foo"
    assert_equal "foo", mr.source_branch
  end
  
  should "it defaults to master for the target_branch" do
    mr = MergeRequest.new
    assert_equal "master", mr.target_branch
    mr.target_branch = "foo"
    assert_equal "foo", mr.target_branch
  end
  
  should "has a source_name" do
    @merge_request.source_branch = "foo"
    assert_equal "#{@merge_request.source_repository.name}:foo", @merge_request.source_name
  end
  
  should "has a target_name" do
    @merge_request.target_branch = "foo"
    assert_equal "#{@merge_request.target_repository.name}:foo", @merge_request.target_name
  end
  
  should "have an empty set of target branches, if the target_repository is nil" do
    @merge_request.target_repository = nil
    assert_equal [], @merge_request.target_branches_for_selection
  end
  
  should "have a set of target branches" do
    repo = repositories(:johans)
    @merge_request.target_repository = repo
    grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    repo.stubs(:git).returns(grit)
    assert_equal grit.heads, @merge_request.target_branches_for_selection
  end
  
  context "with specific starting and ending commits" do
    setup do
      @merge_request.ending_commit = '6823e6622e1da9751c87380ff01a1db1'
    end
    
    should "not blow up if there's no target repository" do
      mr = MergeRequest.new
      assert_nothing_raised do
        assert_equal [], mr.commits_for_selection
      end
    end
    
    should "suggest relevant commits to be merged" do
      assert_equal(4, @merge_request.commits_for_selection.size)
    end
    
    should "know that it applies to specific commits" do
      assert_equal(3, @merge_request.commits_to_be_merged.size)
      exp = %w(6823e6622e1da9751c87380ff01a1db1 526fa6c0b3182116d8ca2dc80dedeafb 286e8afb9576366a2a43b12b94738f07)
      assert_equal(exp, @merge_request.commits_to_be_merged.collect(&:id))
    end
    
    should "return the full set of commits if ending_commit don't exist" do
      @merge_request.ending_commit = '526fa6c0b3182116d8ca2dc80dedeafb'
      assert_equal(2, @merge_request.commits_to_be_merged.size)
    end
    
    should "return an empty set of the ending_commit is already merged" do
      @merge_request.ending_commit = 'alreadymerged'
      assert_equal(0, @merge_request.commits_to_be_merged.size)
    end
  end
  
  context 'The state machine' do
    setup {@merge_request = merge_requests(:moes_to_johans)}
    
    should 'allow transition to other states as long as it is not rejected or merged' do
      @merge_request.open!
      assert @merge_request.can_transition_to?('merge')
      assert @merge_request.can_transition_to?('reject')
    end
    
    should 'not allow transition to other states when rejected' do
      @merge_request.open!
      @merge_request.reject!
      assert !@merge_request.can_transition_to?('merge')
      assert !@merge_request.can_transition_to?('reject')
    end
    
    should 'not allow transitions to other states when merged' do
      @merge_request.open!
      @merge_request.reject!
      assert !@merge_request.can_transition_to?('merge')
      assert !@merge_request.can_transition_to?('reject')
    end
    
    should 'optionally take a block when performing a transition' do
      @merge_request.open!
      @merge_request.expects(:foo=).once
      @merge_request.transition_to('pending') do
        @merge_request.foo = "Hello world"
      end
    end

    should 'optionally take a block when performing a transition' do
      @merge_request.open!
      @merge_request.expects(:foo=).once
      status_changed = @merge_request.transition_to('merge') do
        @merge_request.foo = "Hello world"
      end
      assert status_changed
    end
    
    should 'return false from its transition_to method if the state change is disallowed' do
      @merge_request.stubs(:can_transition_to?).returns(false)
      status_changed = @merge_request.transition_to(MergeRequest::STATUS_MERGED)
      assert !status_changed
    end
    
    should 'deliver a status update to the user who initiated it' do
      assert_incremented_by(@merge_request.user.received_messages, :count, 1) do
        @merge_request.deliver_status_update(users(:moe))
      end
    end
  end
end
