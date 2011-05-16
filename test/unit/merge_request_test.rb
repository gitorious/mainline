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
    commits = ["9dbb89110fc45362fc4dc3f60d960381",
               "6823e6622e1da9751c87380ff01a1db1",
               "526fa6c0b3182116d8ca2dc80dedeafb",
               "286e8afb9576366a2a43b12b94738f07"].collect do |sha|
      m = mock
      m.stubs(:id).returns(sha)
      m
    end
    @merge_request.stubs(:commits_for_selection).returns(commits)
    assert @merge_request.pending_acceptance_of_terms?
  end

  def teardown
    clear_message_queue
  end

  should_validate_presence_of :user, :source_repository, :target_repository
  should_validate_presence_of :summary, :sequence_number

  should_have_many :comments
  should_not_allow_mass_assignment_of :sequence_number

  should 'calculate the merge base between target branch and self' do
    repo = mock("Git repo")
    git = mock("Git")
    repo.stubs(:git).returns(git)
    @merge_request.target_repository.stubs(:git).returns(repo)
    git.expects(:merge_base).with({:timeout => false},
      @merge_request.target_branch, "refs/merge-requests/#{@merge_request.to_param}").returns("ffcaabd\n")
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

  should 'publish a message to the queue when being confirmed by the user' do
    @merge_request.confirmed_by_user

    assert_published("/queue/GitoriousMergeRequestCreation", {
                       "merge_request_id" => @merge_request.id.to_s
                     })
  end

  should "not send messages even if notifications are on" do
    assert_equal 1, @merge_request.target_repository.committerships.count
    cs =  @merge_request.target_repository.committerships.first
    cs.build_permissions(:review); cs.save!
    @merge_request.user = users(:mike)
    @merge_request.save
    assert_no_difference("Message.count", @merge_request.target_repository.reviewers.size) do
      @merge_request.confirmed_by_user
    end
  end

  should "not send messages the subscribers when confirmed by the user, if the target_repo has it turned off" do
    @merge_request.target_repository.update_attribute(:notify_committers_on_new_merge_request, false)
    assert_no_difference("Message.count") do
      @merge_request.confirmed_by_user
    end
  end

  context "default status" do
    setup do
      @project = @merge_request.target_repository.project
    end

    should "find the default state" do
      assert_nil @merge_request.default_status
      MergeRequestStatus.create_defaults_for_project(@project)
      assert_equal @project.merge_request_statuses.first, @merge_request.default_status
    end

    should "use the default status (if any)" do
      MergeRequestStatus.create_defaults_for_project(@project)
      @project.merge_request_statuses.first.update_attribute(:name, "New")
      @merge_request.confirmed_by_user
      assert_equal "New", @merge_request.reload.status_tag.to_s
    end

    should "default to 'Open' if there is no default_status" do
      @merge_request.confirmed_by_user
      assert_equal "Open", @merge_request.reload.status_tag.to_s
      assert_equal MergeRequest::STATUS_OPEN, @merge_request.status
    end
  end

  context "Merge request readyness" do
    should 'have a ready? method which tells whether it has been created in the background' do
      assert !@merge_request.ready?
      v = @merge_request.build_new_version
      assert v.save
      assert @merge_request.ready?
    end

    should "always be ready if it is a legacy merge request" do
      @merge_request.versions.destroy_all
      @merge_request.update_attribute(:legacy, true)
      assert @merge_request.ready?
    end
  end

  should 'be able to update from a push event' do
    @merge_request.expects(:push_new_branch_to_tracking_repo).once
    @merge_request.update_from_push!
    @merge_request.reload
  end

  should "not create an event when updated since this is done inside push_new_branch_to_tracking_repo" do
    @merge_request.stubs(:push_new_branch_to_tracking_repo)
    assert_incremented_by(@merge_request.target_repository.project.events, :size, 0) do
      @merge_request.update_from_push!
    end
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
    version.stubs(:affected_commits).returns([])
    @merge_request.stubs(:versions).returns([version])
    assert_equal [], @merge_request.commit_diff_from_tracking_repo(version.version)
    assert_equal [], @merge_request.commit_diff_from_tracking_repo
  end

  should 'build the name of its merge request branch' do
    @merge_request.stubs(:calculate_merge_base).returns('ff0')
    version = @merge_request.create_new_version
    assert_equal "refs/merge-requests/#{@merge_request.to_param}", @merge_request.merge_branch_name
    assert_equal "refs/merge-requests/#{@merge_request.to_param}/1", @merge_request.merge_branch_name(1)
    assert_equal "refs/merge-requests/#{@merge_request.to_param}/#{version.version}", @merge_request.merge_branch_name(:current)
  end

  should 'push new branch to tracking repo' do
    tracking_repo = mock
    tracking_repo.stubs(:full_repository_path).returns("/tmp/foo.git")
    @merge_request.stubs(:tracking_repository).returns(tracking_repo)
    repo = mock("Target repository")
    repo.expects(:push).once.with({:timeout => false},
      @merge_request.tracking_repository.full_repository_path,
      "refs/merge-requests/#{@merge_request.to_param}:refs/merge-requests/#{@merge_request.to_param}/#{@merge_request.next_version_number}")
    git = mock
    git.stubs(:git).returns(repo)
    @merge_request.target_repository.stubs(:git).returns(git)
    @merge_request.stubs(:calculate_merge_base).returns('ff0')
    assert_incremented_by(@merge_request.versions, :size, 1) do
      @merge_request.push_new_branch_to_tracking_repo
    end
  end

  should "has a closed? status" do
    @merge_request.status = MergeRequest::STATUS_CLOSED
    assert @merge_request.closed?, '@merge_request.closed? should be true'
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

  should 'cache requests to commit_merged?' do
    Rails.cache.expects(:fetch).with("merge_status_for_commit_ff0_in_repository_#{@merge_request.target_repository.id}", :expires_in => 60.minutes).returns(:true)
    Rails.cache.expects(:fetch).with("merge_status_for_commit_ff1_in_repository_#{@merge_request.target_repository.id}", :expires_in => 60.minutes).returns(:false)
    assert @merge_request.commit_merged?('ff0')
    assert !@merge_request.commit_merged?('ff1')
  end

  should "has a statuses class method" do
    assert_equal MergeRequest::STATUS_PENDING_ACCEPTANCE_OF_TERMS, MergeRequest.statuses["Pending"]
    assert_equal MergeRequest::STATUS_OPEN, MergeRequest.statuses["Open"]
    assert_equal MergeRequest::STATUS_CLOSED, MergeRequest.statuses["Closed"]
  end

  should "has a status_string" do
    MergeRequest.statuses.each do |k,v|
      @merge_request.status = v
      assert_equal k.downcase, @merge_request.status_string
    end
  end

  should "knows who can resolve itself" do
    assert @merge_request.resolvable_by?(users(:johan))
    @merge_request.target_repository.committerships.create_with_permissions!({
        :committer => groups(:team_thunderbird)
      }, Committership::CAN_REVIEW)
    assert @merge_request.resolvable_by?(users(:mike))
    assert !@merge_request.resolvable_by?(users(:moe))
  end

  should "be resolvable by the MR creator as well" do
    creator = @merge_request.user = users(:mike)
    @merge_request.save!
    @merge_request.target_repository.committerships.each(&:destroy)
    assert !creator.can_write_to?(@merge_request.target_repository)
    assert @merge_request.resolvable_by?(creator), "not resolvable by creator"
    assert !@merge_request.resolvable_by?(users(:moe))
  end

  should "have a working resolvable_by? together with fucktard authentication systems" do
    assert !@merge_request.resolvable_by?(:false)
  end

  should "count open merge_requests" do
    mr = @merge_request.clone
    mr.status = MergeRequest::STATUS_CLOSED
    mr.save
    assert_equal 2, MergeRequest.count_open
  end

  should 'have a transition from pending to open' do
    mr = @merge_request.clone
    assert mr.pending_acceptance_of_terms?
    
    mr.expects(:valid_oauth_credentials?).returns(true)
    mr.expects(:fetch_contribution_notice)
    
    mr.terms_accepted
    assert mr.open?
  end

  should "load contribution data from OAuth" do
    agreement_version = 'valid_version_sha'
    body = 'Thank you for your contribution'
    @merge_request.expects(:access_token).returns(access_token_for_testing(agreement_version, body))
    @merge_request.fetch_contribution_notice
    assert_equal agreement_version, @merge_request.contribution_agreement_version
    assert_equal body, @merge_request.contribution_notice
  end

  # Returns a stub access token which will always return a HTTPAccepted with the headers required
  def access_token_for_testing(version_code, body)
    response = Net::HTTPAccepted.new(nil,nil,nil)
    response["X-Contribution-Agreement-Version"] = version_code
    response.stubs(:body).returns(body)
    mock(:post => response)
  end

  should 'not be set to open if OAuth validation fails' do
    mr = @merge_request.clone
    mr.expects(:valid_oauth_credentials?).returns(false)
    mr.terms_accepted
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

    should "not blow up if there is no target repository" do
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
      @merge_request.versions.destroy_all
      assert_equal 4, @merge_request.commits_for_selection.size
      assert_equal 3, @merge_request.commits_to_be_merged.size
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
      assert @merge_request.can_transition_to?('close')
    end

    should 'not allow transition to other states when rejected' do
      @merge_request.open!
      @merge_request.close!
      assert !@merge_request.can_transition_to?('open')
    end

    should 'optionally take a block when performing a transition' do
      @merge_request.open!
      @merge_request.expects(:foo=).once
      status_changed = @merge_request.transition_to('close') do
        @merge_request.foo = "Hello world"
      end
      assert status_changed
    end

    should 'allow admin users to re-open' do
      @user = users(:johan)
      @merge_request.open
      @merge_request.close
      assert @merge_request.closed?
      assert @merge_request.can_be_reopened_by?(@user)
      assert @merge_request.reopen_with_user(@user)
      assert @merge_request.open?
    end

    should 'not allow non-admin users to re-open' do
      @user = users(:moe)
      @merge_request.open
      @merge_request.close
      assert @merge_request.closed?
      assert !@merge_request.can_be_reopened_by?(@user)
      assert !@merge_request.reopen_with_user(@user)
      assert !@merge_request.open?
    end

    should 'return false from its transition_to method if the state change is disallowed' do
      @merge_request.stubs(:can_transition_to?).returns(false)
      status_changed = @merge_request.transition_to(MergeRequest::STATUS_OPEN)
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

    should_eventually 'provide a hash of labels and values for possible next states' do
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

    should_eventually 'have a pseudo-open status' do
      [MergeRequest::STATUS_OPEN].each do |s|
        @merge_request.status = s
        # TODO: get rid of #open_or_in_verification?
        assert @merge_request.open_or_in_verification?
      end
    end
  end


  context 'Compatibility with existing records' do
    setup do
      @source_repo = repositories(:johans2)
      @target_repo = repositories(:johans)
      @user = users(:johan)
      @merge_request = MergeRequest.new({
          :source_repository => @source_repo,
          :target_repository => @target_repo,
          :user => @user,
          :summary => 'Please, mister postman',
          :proposal => 'Please, mister postman'
        })
      @merge_request.sequence_number = @target_repo.next_merge_request_sequence_number
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

  should 'have a recently_added? method' do
    @merge_request.versions.destroy_all
    @merge_request.created_at = 3.minutes.ago
    assert !@merge_request.recently_created?
    @merge_request.created_at = 1.minute.ago
    assert @merge_request.recently_created?
  end

  context "from_filter" do
    setup do
      @repo = repositories(:johans)
      merge_requests(:mikes_to_johans).destroy
      merge_requests(:moes_to_johans).update_attribute(:status, MergeRequest::STATUS_OPEN)
      MergeRequestStatus.create_defaults_for_project(@repo.project)
    end

    should "default to open merge-requests" do
      merge_requests(:moes_to_johans).update_attribute(:status_tag, 'Closed')
      merge_requests(:moes_to_johans_open).update_attribute(:status_tag, 'Open')
      assert !@repo.merge_requests.from_filter(nil).include?(merge_requests(:moes_to_johans))
      assert_equal [merge_requests(:moes_to_johans_open)], @repo.merge_requests.from_filter(nil)
    end

    should "fall back to using named_scope on other filter name" do
      merge_requests(:moes_to_johans).update_attribute(:status_tag, 'kittens')
      assert !@repo.merge_requests.from_filter("kittens").include?(merge_requests(:moes_to_johans_open))
      assert_equal [merge_requests(:moes_to_johans)], @repo.merge_requests.from_filter("kittens")
    end

    should "find closed merge-requests" do
      merge_requests(:moes_to_johans).update_attribute(:status_tag, 'Closed')
      assert !@repo.merge_requests.from_filter("Closed").include?(merge_requests(:moes_to_johans_open))
      assert_equal [merge_requests(:moes_to_johans)], @repo.merge_requests.from_filter("Closed")
    end
  end

  context 'As XML' do
    setup {@merge_request = merge_requests(:moes_to_johans_open)}

    should 'not include confidential information' do
      assert !@merge_request.to_xml.include?('<contribution-agreement-version')
      assert !@merge_request.to_xml.include?('<oauth-secret')
    end

    should 'include enough information for our purposes' do
      assert_match(/<status>#{@merge_request.status_tag}<\/status>/,
        @merge_request.to_xml)
      assert_match(/<username>~#{@merge_request.user.title}<\/username>/,
        @merge_request.to_xml)
      assert_match(/<proposal>#{@merge_request.proposal}<\/proposal>/,
        @merge_request.to_xml)
      assert_match(/<summary>#{@merge_request.summary}<\/summary>/,
        @merge_request.to_xml)
    end

    should "use the sequence number instead of id" do
      assert_match(/<id>#{@merge_request.sequence_number}<\/id>/,
        @merge_request.to_xml)
    end

    should "include comments" do
      comments = [mock(:user => users(:johan), :created_at => Time.now, :updated_at => Time.now, :body => "fff", :id => 901)]
      version = mock(:comments => comments, :merge_base_sha => "", :updated_at => Time.now, :version => "1")
      @merge_request.expects(:versions).returns([version])

      xml_payload = @merge_request.to_xml
      assert_match(/<comment .*author="#{users(:johan).title}".*>/, xml_payload)
    end
  end

  context 'Pushing changes to the merge request repository' do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
    end

    should 'send a push command from the source repository to the tracking repository' do
      merge_request_repo = @merge_request.target_repository.create_tracking_repository
      merge_request_repo_path = merge_request_repo.full_repository_path
      branch_spec_base = "#{@merge_request.ending_commit}:refs/merge-requests"
      branch_spec = [branch_spec_base, @merge_request.to_param].join('/')
      tracking_branch_spec = [branch_spec_base, @merge_request.to_param, 1].join('/')

      git = mock("Git")
      git_backend = mock("Source repository git")
      git.stubs(:git).returns(git_backend)
      @merge_request.source_repository.stubs(:git).returns(git)
      @merge_request.expects(:push_new_branch_to_tracking_repo).twice

      git_backend.expects(:push).with({:timeout => false},
        @merge_request.target_repository.full_repository_path, branch_spec).once
      @merge_request.push_to_tracking_repository!
      git_backend.expects(:push).with({:force => true,:timeout => false},
        @merge_request.target_repository.full_repository_path, branch_spec).once
      @merge_request.push_to_tracking_repository!(true)
    end

    context "Update events" do
      setup do
        git = mock("Git")
        @git_backend = mock("tracking repository git")
        git.stubs(:git).returns(@git_backend)
        @merge_request.target_repository.stubs(:git).returns(git)
        @git_backend.stubs(:merge_base).returns("abc")
      end

      should "not create a 'new version' event if it is the first version" do
        @git_backend.expects(:push)
        assert_no_difference("Event.count") do
          @merge_request.push_new_branch_to_tracking_repo
        end
      end

      should "create a 'new version' event unless it is the first version" do
        @git_backend.expects(:push)
        @merge_request.create_new_version
        assert_difference("Event.count") do
          @merge_request.push_new_branch_to_tracking_repo
        end
        assert_equal Action::UPDATE_MERGE_REQUEST, Event.last.action
      end
    end
  end

  context 'Status tags' do
    setup do
      @merge_request = merge_requests(:moes_to_johans_open)
      MergeRequestStatus.create_defaults_for_project(
        @merge_request.target_repository.project)
    end

    should 'cascade to the actual state machine with given states' do
      @merge_request.status_tag = 'closed'
      assert @merge_request.reload.closed?
      @merge_request.status_tag = 'open'
      assert @merge_request.reload.open?
    end

    should "set the internal statemachine accordingly" do
      project = @merge_request.target_repository.project
      project.merge_request_statuses.create!(:name => "In Progress",
        :state => MergeRequest::STATUS_OPEN, :color => "#000")
      project.merge_request_statuses.create!(:name => "All Done",
        :state => MergeRequest::STATUS_CLOSED, :color => "#ccc")

      @merge_request.status_tag = "In Progress"
      assert @merge_request.reload.open?
      @merge_request.status_tag = "All Done"
      assert @merge_request.reload.closed?
    end

    should "set the status_tag to open when new merge requests are created" do
      new_request = MergeRequest.new(:user => @merge_request.user,
        :source_repository => @merge_request.source_repository,
        :target_repository => @merge_request.target_repository,
        :summary => "Add a user",
        :proposal => "Please add me",
        :ending_commit => "a"*10, :source_branch => "master", :target_branch => "master")
      assert new_request.save!
      assert new_request.status_tag.blank?
      new_request.confirmed_by_user
      assert_instance_of StatusTag, new_request.status_tag
      assert_equal "Open", new_request.status_tag.name
    end

    should 'build an event with from and to when changing between states' do
      @merge_request.with_user(users(:johan)) do
        @merge_request.status_tag = 'before'
        @merge_request.status_tag = 'after'
        @merge_request.create_status_change_event("Foo")
        event = @merge_request.events.reload.last
        exp ="State changed from <span class=\"changed\">before</span> " +
          "to <span class=\"changed\">after</span>"
        assert_equal exp, event.data
      end
    end

    should 'build an event with only the new state' do
      @merge_request.write_attribute(:status_tag, nil)
      @merge_request.with_user(users(:johan)) do
        @merge_request.status_tag = "Closed"
        @merge_request.create_status_change_event("Setting this to closed")
        event = @merge_request.events.reload.last
        assert_equal "State changed to <span class=\"changed\">Closed</span>", event.data
      end
    end

    should 'create an event with a given user if such is provided' do
      @merge_request.status_tag = 'before'
      @merge_request.with_user(users(:johan)) do
        @merge_request.status_tag = 'after'
        @merge_request.create_status_change_event "Updated this"
        event = @merge_request.events.reload.last
        assert_equal users(:johan), event.user
      end
    end
  end

  context 'Migration of reason/status to comment/status_tag' do
    setup {@merge_request = merge_requests(:moes_to_johans_open)}

    should 'simply set the status tag if no reason exists' do
      @merge_request.migrate_to_status_tag
      assert_equal 'Open', @merge_request.reload.status_tag.to_s
    end

    should 'add a comment and set the state when reason exists' do
      @merge_request.reason = "You are right, this is a great idea!"
      @merge_request.close
      @merge_request.save
      @merge_request.migrate_to_status_tag
      assert_equal 'closed', @merge_request.reload.status_string
      assert_not_nil comment = @merge_request.comments.reload.last
      assert_equal @merge_request.updated_by, comment.user
    end
  end

  context "Soft deletion of merge requests" do
    setup do
      @merge_request = merge_requests(:moes_to_johans_open)
    end

    should "make the merge request unfindable" do
      @merge_request.destroy

      assert_nil MergeRequest.find_by_id(@merge_request.id)
    end

    should "send a message when being destroyed" do
      @merge_request.destroy
      mr = @merge_request

      assert_published("/queue/GitoriousMergeRequestBackend", {
                         "merge_request_id" => mr.id.to_s,
                         "action" => "delete",
                         "target_path" => mr.target_repository.full_repository_path,
                         "target_name" => mr.target_repository.url_path,
                         "merge_branch_name" => mr.merge_branch_name,
                         "target_repository_id" => mr.target_repository.id,
                         "source_repository_id" => mr.source_repository.id,
                       })
    end
  end

  context "Commenting" do
    setup do
      @merge_request = merge_requests(:johans_to_mikes)
      @comments = ["Looks good", "On the other hand..."].map do |body|
        @merge_request.comments.create!({
            :project => @merge_request.target_repository.project,
            :body => body,
            :sha1 => "ffac",
            :user => User.first
          })
      end
    end

    should 'include comments on versions' do
      version_comment = comments(:first_merge_request_version_comment)
      assert @merge_request.cascaded_comments.include?(version_comment)
    end

    should 'include comments on the merge request' do
      assert @merge_request.cascaded_comments.include? @comments.first
    end
  end



  context "Sequence numbers" do
    setup {
      @repository = repositories(:johans)
      @merge_request = @repository.merge_requests.build(
        :user => users(:moe),
        :source_repository => repositories(:moes),
        :summary => "Please merge",
        :proposal => "New window decorations",
        :sha_snapshot => "ffac",
        :ending_commit => "ac00"
        )
    }
    should "set the sequence number on create" do
      next_sequence = @repository.next_merge_request_sequence_number
      assert @merge_request.save
      assert_equal next_sequence + 1, @repository.next_merge_request_sequence_number
      assert_equal(next_sequence, @merge_request.sequence_number)
    end

    should "require a unique sequence number for each target repo" do
      assert @merge_request.save
      mr2 = @merge_request.clone
      assert mr2.save
      mr2.sequence_number = @merge_request.sequence_number
      assert_equal mr2.sequence_number, @merge_request.sequence_number
      assert !mr2.save
      assert_equal mr2.sequence_number, @merge_request.sequence_number
      assert_not_nil mr2.errors.on(:sequence_number)
    end

    should "use sequence_number in to_param" do
      @merge_request.update_attribute(:sequence_number, @repository.next_merge_request_sequence_number)
      assert_equal @merge_request.sequence_number.to_s, @merge_request.to_param
    end
  end

  context "Reviewers" do
    setup do
      @source_repository = repositories(:johans)
      @user = @source_repository.user
      @target_repository = repositories(:moes)
      @merge_request = @target_repository.merge_requests.build(
        :source_repository => @source_repository,
        :summary => "Please merge",
        :sha_snapshot => "ffac",
        :ending_commit => "caff",
        :user => @user
        )
    end

    should "be accessible from the merge request" do
      assert_equal(@merge_request.target_repository.reviewers.uniq.reject{|r|r == @merge_request.user},
        @merge_request.reviewers)
    end
    
    should "add a favorite for each reviewer" do
      @merge_request.expects(:add_to_reviewers_favorites).times(@merge_request.reviewers.size)
      @merge_request.notify_subscribers_about_creation
    end

    should "add self to reviewer's favorites" do
      reviewer = users(:johan)
      assert_incremented_by(reviewer.favorites, :size, 1) do
        @merge_request.add_to_reviewers_favorites(reviewer)
      end
    end

    should "be able to find its event" do
      creation_event = @merge_request.add_creation_event(
        @target_repository.project,@user)
      assert_equal creation_event, @merge_request.creation_event
    end

    should "return nil when no creation event exists" do
      assert_nil @merge_request.creation_event
    end

    should "create a feed item for each watcher" do
      @merge_request.add_creation_event(@target_repository.project, @user)
      assert_incremented_by(FeedItem, :count, @merge_request.reviewers.size) do
        @merge_request.notify_subscribers_about_creation
      end
    end

    should "be added to creators favorites" do
      assert_incremented_by(@user.favorites, :size, 1) {
        @merge_request.save
      }
    end
    
  end

  context "Watchable" do
    setup do
      @merge_request = merge_requests(:johans_to_mikes)
    end

    should "have the target repository's project as project" do
      assert_equal(@merge_request.target_repository.project,
        @merge_request.project)
    end
  end
  
end
