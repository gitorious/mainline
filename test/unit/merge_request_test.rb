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
  
  should_validate_presence_of :user, :source_repository, :target_repository
  
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
  
  should 'calculate the merge base between target branch and self' do
    repo = mock("Git repo")
    git = mock("Git")
    repo.stubs(:git).returns(git)
    @merge_request.target_repository.stubs(:git).returns(repo)
    git.expects(:merge_base).with({}, @merge_request.target_branch, "refs/merge-requests/#{@merge_request.id}").returns("ffcaabd\n")
    assert_equal 'ffcaabd', @merge_request.calculate_merge_base
  end
  
  should 'create a version with the merge base' do
    @merge_request.expects(:calculate_merge_base).returns('ffcaabd')
    version = @merge_request.create_new_version
    assert_equal 1, version.version
    assert_equal "ffcaabd", version.merge_base_sha
  end
  
  should 'generate valid version numbers for its version' do
    version = @merge_request.build_new_version
    assert version.save
    assert_equal 1, version.version
    version = @merge_request.build_new_version
    assert version.save
    assert_equal 2, version.version
  end
  
  should 'send a MQ message when being confirmed by the user' do
    p = proc {@merge_request.confirmed_by_user}
    message = find_message_with_queue_and_regexp('/queue/GitoriousMergeRequestCreation', /.*/) {p.call}
    assert_equal({'merge_request_id' => @merge_request.id.to_s}, message)
  end
  
  should 'have a ready? method which tells whether it has been created in the background' do
    assert !@merge_request.ready?
    v = @merge_request.build_new_version
    assert v.save
    assert @merge_request.ready?
  end
  
  should "has a merged? status" do
    @merge_request.status = MergeRequest::STATUS_MERGED
    assert @merge_request.merged?, '@merge_request.merged? should be true'
  end
  
  should 'be able to update from a push event' do
    @merge_request.expects(:push_new_branch_to_tracking_repo).once
    @merge_request.update_from_push!
    @merge_request.reload
  end
  
  should "return its target repository's tracking repository" do
    tracking_repo = @merge_request.target_repository.create_tracking_repository
    assert_equal tracking_repo, @merge_request.tracking_repository
  end
  
  should 'create a new version with the merge base between target branch and self' do
    @merge_request.expects(:calculate_merge_base).returns('ff0')
    version = @merge_request.create_new_version
    assert_equal 'ff0', version.merge_base_sha
  end

  should 'calculate commit diff from tracking repo' do
    @merge_request.stubs(:calculate_merge_base).returns('ff0')
    version = @merge_request.create_new_version
    repo = mock("Tracking git repo")
    repo.expects(:commits_between).with('ff0', "refs/merge-requests/#{@merge_request.id}/#{version.version}").returns([])
    tracking_repo = mock("Tracking repository")
    @merge_request.stubs(:tracking_repository).returns(tracking_repo)
    tracking_repo.stubs(:git).returns(repo)
    assert_equal [], @merge_request.commit_diff_from_tracking_repo(version.version)
    assert_equal [], @merge_request.commit_diff_from_tracking_repo
  end

  should 'build the name of its merge request branch' do
    @merge_request.stubs(:calculate_merge_base).returns('ff0')
    version = @merge_request.create_new_version
    assert_equal "refs/merge-requests/#{@merge_request.id}", @merge_request.merge_branch_name
    assert_equal "refs/merge-requests/#{@merge_request.id}/1", @merge_request.merge_branch_name(1)
    assert_equal "refs/merge-requests/#{@merge_request.id}/#{version.version}", @merge_request.merge_branch_name(:current)
  end
  
  should 'push new branch to tracking repo' do
    tracking_repo = mock
    tracking_repo.stubs(:full_repository_path).returns("/tmp/foo.git")
    @merge_request.stubs(:tracking_repository).returns(tracking_repo)
    repo = mock("Target repository")
    repo.expects(:push).once.with({}, 
      @merge_request.tracking_repository.full_repository_path,
      "refs/merge-requests/#{@merge_request.id}:refs/merge-requests/#{@merge_request.id}/#{@merge_request.version+1}")
    git = mock
    git.stubs(:git).returns(repo)
    @merge_request.target_repository.stubs(:git).returns(git)
    @merge_request.stubs(:calculate_merge_base).returns('ff0')
    assert_incremented_by(@merge_request.versions, :size, 1) do
      @merge_request.push_new_branch_to_tracking_repo
    end
  end
  
  should "has a rejected? status" do
    @merge_request.status = MergeRequest::STATUS_REJECTED
    assert @merge_request.rejected?, '@merge_request.rejected? should be true'
  end
  
  should "has a open? status" do
    @merge_request.status = MergeRequest::STATUS_OPEN
    assert @merge_request.open?, '@merge_request.open? should be true'
  end

  should 'know if a specific commit has been merged or not' do
    repo = mock("Git repo")
    git = mock("Git backend")
    repo.stubs(:git).returns(git)
    @merge_request.target_repository.stubs(:git).returns(repo)
    git.expects(:cherry).with({}, @merge_request.target_branch, 'ff0').returns('')
    git.expects(:cherry).with({}, @merge_request.target_branch, 'ffc').returns('+ bbacd')
    assert !@merge_request.commit_merged?('ffc')
    assert @merge_request.commit_merged?('ff0')
  end
  
  should 'have a verifying? status' do
    @merge_request.status = MergeRequest::STATUS_VERIFYING
    assert @merge_request.verifying?, '@merge_request.verifying? should be true'
  end
  
  should "has a statuses class method" do
    assert_equal MergeRequest::STATUS_PENDING_ACCEPTANCE_OF_TERMS, MergeRequest.statuses["Pending"]
    assert_equal MergeRequest::STATUS_OPEN, MergeRequest.statuses["Open"]
    assert_equal MergeRequest::STATUS_MERGED, MergeRequest.statuses["Merged"]
    assert_equal MergeRequest::STATUS_REJECTED, MergeRequest.statuses["Rejected"]
    assert_equal MergeRequest::STATUS_VERIFYING, MergeRequest.statuses['Verifying']
  end
  
  should "has a status_string" do
    MergeRequest.statuses.each do |k,v|
      @merge_request.status = v
      assert_equal k.downcase, @merge_request.status_string
    end
  end
  
  should "knows who can resolve itself" do
    assert @merge_request.resolvable_by?(users(:johan))
    @merge_request.target_repository.committerships.create!(:committer => groups(:team_thunderbird))
    assert @merge_request.resolvable_by?(users(:mike))
    assert !@merge_request.resolvable_by?(users(:moe))
  end
  
  should "have a working resolvable_by? together with fucktard authentication systems" do
    assert !@merge_request.resolvable_by?(:false)
  end
  
  should "count open merge_requests" do
    mr = @merge_request.clone
    mr.status = MergeRequest::STATUS_REJECTED
    mr.save
    assert_equal 2, MergeRequest.count_open
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
    
    should 'show a list of potential commits' do
      assert_equal 3, @merge_request.potential_commits.size
    end

    should 'access its versions by version number' do
      @merge_request.stubs(:calculate_merge_base).returns('ffac')
      3.times{@merge_request.create_new_version}
      assert_nil @merge_request.version_number(4)
      assert_equal 3, @merge_request.version_number(3).version
    end
    
    should 'use the real commits if the target branch has been updated' do
      @merge_request.stubs(:calculate_merge_base).returns('ff0')
      @merge_request.create_new_version
      @merge_request.expects(:commit_diff_from_tracking_repo).once
      @merge_request.commits_to_be_merged
    end
    
    should 'return an empty list if the target branch has not been updated' do
      @merge_request.version = 0
      assert_equal [], @merge_request.commits_to_be_merged
    end
    
    should 'know if the specified commit exists in the source repository' do
      source_git = mock('Source repository Git repo')
      source_git.expects(:commit).with('ff00ddca').returns(nil)
      source_git.expects(:commit).with('ff00ddcb').returns(mock("Ending commit"))
      @merge_request.source_repository.stubs(:git).returns(source_git)
      @merge_request.ending_commit = 'ff00ddca'
      assert !@merge_request.ending_commit_exists?
      @merge_request.ending_commit = 'ff00ddcb'
      assert @merge_request.ending_commit_exists?
    end
  end
  
  context 'The state machine' do
    setup {@merge_request = merge_requests(:moes_to_johans)}
    
    should 'allow transition to other states as long as it is not rejected or merged' do
      @merge_request.open!
      assert @merge_request.can_transition_to?('merge')
      assert @merge_request.can_transition_to?('reject')
      assert @merge_request.can_transition_to?('in_verification')
    end
    
    should 'not allow transition to other states when rejected' do
      @merge_request.open!
      @merge_request.reject!
      assert !@merge_request.can_transition_to?('merge')
      assert !@merge_request.can_transition_to?('reject')
      assert !@merge_request.can_transition_to?('in_verification')
    end
    
    should 'not allow transitions to other states when merged' do
      @merge_request.open!
      @merge_request.reject!
      assert !@merge_request.can_transition_to?('merge')
      assert !@merge_request.can_transition_to?('reject')
      assert !@merge_request.can_transition_to?('in_verification')
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
    
    should 'allow admin users to re-open' do
      @user = users(:johan)
      @merge_request.open
      @merge_request.reject
      assert @merge_request.rejected?
      assert @merge_request.can_be_reopened_by?(@user)
      assert @merge_request.reopen_with_user(@user)
      assert @merge_request.open?
    end
    
    should 'not allow non-admin users to re-open' do
      @user = users(:moe)
      @merge_request.open
      @merge_request.reject
      assert @merge_request.rejected?
      assert !@merge_request.can_be_reopened_by?(@user)
      assert !@merge_request.reopen_with_user(@user)
      assert !@merge_request.open?
    end
    
    should 'not allow non-closed merge request to reopen' do
      @merge_request.open
      assert !@merge_request.can_reopen?
      @merge_request.reject
      assert @merge_request.can_reopen?
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
    
    should 'nullify associated messages when deleted' do
      @merge_request.deliver_status_update(users(:moe))
      message = @merge_request.user.received_messages.last
      @merge_request.destroy
      message.reload
      assert_nil message.notifiable
    end
    
    should 'provide a hash of labels and values for possible next states' do
      @merge_request.status = MergeRequest::STATUS_VERIFYING
      assert_equal({'Merged' => 'merge', 'Rejected' => 'reject'}, @merge_request.possible_next_states_hash)
      @merge_request.status = MergeRequest::STATUS_OPEN
      assert_equal({'Merged' => 'merge', 'Rejected' => 'reject', 'Verifying' => 'in_verification'}, @merge_request.possible_next_states_hash)
      @merge_request.status = MergeRequest::STATUS_REJECTED
      assert_equal({}, @merge_request.possible_next_states_hash)
      @merge_request.status = MergeRequest::STATUS_PENDING_ACCEPTANCE_OF_TERMS
      assert_equal({'Open' => 'open'}, @merge_request.possible_next_states_hash)
      @merge_request.status = MergeRequest::STATUS_MERGED
      assert_equal({}, @merge_request.possible_next_states_hash)
    end
    
    should 'have a pseudo-open status' do
      [MergeRequest::STATUS_VERIFYING, MergeRequest::STATUS_OPEN].each do |s|
        @merge_request.status = s
        assert @merge_request.open_or_in_verification?
      end
    end
  end
  
  context 'Compatibility with existing records' do
    setup do
      @source_repo = repositories(:johans2)
      @target_repo = repositories(:johans)
      @user = users(:johan)
      @merge_request = MergeRequest.new(:source_repository => @source_repo, :target_repository => @target_repo, :user => @user, :proposal => 'Please, mister postman')
    end
    
    should 'require ending_commit for new records' do
      assert !@merge_request.save
      assert_not_nil @merge_request.errors.on(:ending_commit)
    end
    
    should 'not consider a missing ending_commit a show stopper on update' do
      @merge_request.save(false)
      @merge_request.proposal = 'Yikes'
      assert @merge_request.save
    end
  end
  
  context 'Last updated by' do
    setup do
      @merge_request = merge_requests(:moes_to_johans_open)
    end
    
    should 'initially be the user' do
      assert_equal users(:johan), @merge_request.updated_by
    end

    should 'have a setter and getter' do
      @merge_request.updated_by = users(:mike)
      assert_equal users(:mike), @merge_request.updated_by
    end    
  end
  
  context "from_filter" do
    setup do
      @repo = repositories(:johans)
      merge_requests(:mikes_to_johans).destroy
    end
    
    should "default to open merge-requests" do
      merge_requests(:moes_to_johans).update_attribute(:status, MergeRequest::STATUS_MERGED)
      assert !@repo.merge_requests.from_filter(nil).include?(merge_requests(:moes_to_johans))
      assert_equal [merge_requests(:moes_to_johans_open)], @repo.merge_requests.from_filter(nil)
    end
    
    should "fall back to open merge-requests on invalid filter name" do
      merge_requests(:moes_to_johans).update_attribute(:status, MergeRequest::STATUS_MERGED)
      assert !@repo.merge_requests.from_filter("kittens").include?(merge_requests(:moes_to_johans))
      assert_equal [merge_requests(:moes_to_johans_open)], @repo.merge_requests.from_filter("kittens")
    end
    
    should "find merged merge-requests" do
      merge_requests(:moes_to_johans).update_attribute(:status, MergeRequest::STATUS_MERGED)
      assert !@repo.merge_requests.from_filter("merged").include?(merge_requests(:moes_to_johans_open))
      assert_equal [merge_requests(:moes_to_johans)], @repo.merge_requests.from_filter("merged")
    end
    
    should "find rejected merge-requests" do
      merge_requests(:moes_to_johans).update_attribute(:status, MergeRequest::STATUS_REJECTED)
      assert !@repo.merge_requests.from_filter("rejected").include?(merge_requests(:moes_to_johans_open))
      assert_equal [merge_requests(:moes_to_johans)], @repo.merge_requests.from_filter("rejected")
    end
  end

  context 'As XML' do
    setup {@merge_request = merge_requests(:moes_to_johans_open)}
    
    should 'not include confidential information' do
      assert !@merge_request.to_xml.include?('<contribution-agreement-version')
      assert !@merge_request.to_xml.include?('<oauth-secret')
    end
    
    should 'include enough information for our purposes' do
      assert_match(/<status>#{@merge_request.status_string}<\/status>/, @merge_request.to_xml)
      assert_match(/<username>~#{@merge_request.user.title}<\/username>/, @merge_request.to_xml)
      assert_match(/<proposal>#{@merge_request.proposal}<\/proposal>/, @merge_request.to_xml)
    end
  end
  
  context 'Pushing changes to the merge request repository' do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
    end
    
    should 'send a push command from the source repository to the merge request repository' do
      merge_request_repo = @merge_request.target_repository.create_tracking_repository
      merge_request_repo_path = merge_request_repo.full_repository_path
      branch_spec_base = "#{@merge_request.ending_commit}:refs/merge-requests"
      branch_spec = [branch_spec_base, @merge_request.id].join('/')
      tracking_branch_spec = [branch_spec_base, @merge_request.id, 1].join('/')
      
      git = mock("Git")
      git_backend = mock("Source repository git")
      git.stubs(:git).returns(git_backend)
      @merge_request.source_repository.stubs(:git).returns(git)
      @merge_request.expects(:push_new_branch_to_tracking_repo).twice
      
      git_backend.expects(:push).with({}, @merge_request.target_repository.full_repository_path, branch_spec).once
      @merge_request.push_to_tracking_repository!
      git_backend.expects(:push).with({:force => true}, @merge_request.target_repository.full_repository_path, branch_spec).once
      @merge_request.push_to_tracking_repository!(true)
    end
  end
  
  context 'As XML' do
    setup {@merge_request = merge_requests(:moes_to_johans_open)}
    
    should 'not include confidential information' do
      assert !@merge_request.to_xml.include?('<contribution-agreement-version')
      assert !@merge_request.to_xml.include?('<oauth-secret')
    end
    
    should 'include enough information for our purposes' do
      assert_match(/<status>#{@merge_request.status_string}<\/status>/, @merge_request.to_xml)
      assert_match(/<username>~#{@merge_request.user.title}<\/username>/, @merge_request.to_xml)
      assert_match(/<proposal>#{@merge_request.proposal}<\/proposal>/, @merge_request.to_xml)
    end
  end
  
  context 'Status tags' do
    setup {@merge_request = merge_requests(:moes_to_johans_open)}
    
    should 'cascade to the actual state machine with given states' do
      @merge_request.status_tag = 'merged'
      assert @merge_request.reload.merged?
      @merge_request.status_tag = 'rejected'
      assert @merge_request.rejected?
      @merge_request.status_tag = 'in_verification'
      assert @merge_request.verifying?
    end
  end
end
