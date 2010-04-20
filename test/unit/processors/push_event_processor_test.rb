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


require File.dirname(__FILE__) + '/../../test_helper'

class PushEventProcessorTest < ActiveSupport::TestCase

  def setup
    @processor = PushEventProcessor.new
  end
  
  should "update the last_pushed_at attribute on initial push" do
    stub_git_show
    stub_git_log_and_user
    repo = repositories(:johans)
    repo.update_attribute(:last_pushed_at, nil)
    @processor.expects(:log_events).returns(true)
    @processor.expects(:trigger_hooks)
    json = {
      :gitdir => repo.hashed_path,
      :username => "johan",
      :message => '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/heads/master',
    }.to_json
    @processor.on_message(json)
    assert_equal users(:johan), @processor.user
    assert_equal repo, @processor.repository
    assert_not_nil repo.reload.last_pushed_at
    assert repo.last_pushed_at > 5.minutes.ago
  end

  should "not update the last_pushed_at when updating a merge request" do
    stub_git_show
    stub_git_log_and_user
    repo = repositories(:johans)
    repo.update_attribute(:last_pushed_at, nil)
    @processor.expects(:log_events).returns(true)
    json = {
      :gitdir => repo.hashed_path,
      :username => "johan",
      :message => '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/merge-requests/42',
    }.to_json
    @processor.on_message(json)
    assert_nil repo.reload.last_pushed_at, "last_pushed_at was updated"
  end
  
  should "returns the correct type and identifier for a new tag" do
    stub_git_show
    @processor.process_push_from_commit_summary "0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/tags/r1.1"
    assert_equal :create, @processor.action
    assert @processor.tag?
    
    assert_equal 1, @processor.events.size
    assert_equal Action::CREATE_TAG, @processor.events.first.event_type
    assert_equal 'r1.1', @processor.events.first.identifier
    
    @processor.expects(:log_event).once
    @processor.log_events
  end
  
  should 'identify non-standard (review) branches, and exclude these from logging' do
    stub_git_show 
    @processor.process_push_from_commit_summary "0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/merge-requests/123"
    assert_equal :create, @processor.action
    assert @processor.review?
    assert_equal 0, @processor.events.size
    @processor.expects(:log_event).never
    @processor.log_events
  end
  
  should "returns the correct type and identifier for a new branch" do
    stub_git_log_and_user
    @processor.process_push_from_commit_summary '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/heads/foo_branch'
    @processor.repository = Repository.first
    assert_equal :create, @processor.action
    assert @processor.head?
    assert_equal 1, @processor.events.size
    assert_equal Action::CREATE_BRANCH, @processor.events.first.event_type
    assert_equal 'foo_branch', @processor.events.first.identifier
    assert_equal users(:johan), @processor.events.first.user
    @processor.expects(:log_event).times(1)
    @processor.log_events    
  end
  
  should "return the correct namespaced identifier for a new branch" do
     stub_git_log_and_user
     @processor.process_push_from_commit_summary '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/heads/foo/bar_branch'
     assert_equal 'foo/bar_branch', @processor.events.first.identifier
   end
  
  should 'only fetch commits for new branches when the new branch is master' do
    stub_git_log_and_user
    @processor.process_push_from_commit_summary '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/heads/master'
    @processor.repository = Repository.first
    assert_equal :create, @processor.action
    assert @processor.head?
    assert_equal 4, @processor.events.size
    assert_equal Action::CREATE_BRANCH, @processor.events.first.event_type
    assert_equal 'master', @processor.events.first.identifier
    assert_equal Action::COMMIT, @processor.events[1].event_type
    @processor.expects(:log_event).times(4)
    @processor.log_events
  end
  
  should "returns the correct type and a set of events for a commit" do
    stub_git_log_and_user
    @processor.process_push_from_commit_summary "a9934c1d3a56edfa8f45e5f157869874c8dc2c34 33f746e21ef5122511a5a69f381bfdf017f4d66c refs/heads/foo_branch"
    @processor.repository = Repository.first
    assert_equal :update, @processor.action
    assert @processor.head?
    assert_equal 1, @processor.events.size
    first_event = @processor.events.first
    assert_equal Action::PUSH, first_event.event_type
    assert_equal users(:johan).email, first_event.email
    assert_match(/foo_branch changed/, first_event.message)
    assert_equal(3, first_event.commits.size)
    
    assert_incremented_by(Event, :count, 4) do
      @processor.log_events
    end
  end
  
  should "set the correct user for the commit subevent, if a user exists with that email" do
    emails(:johans1).update_attribute(:address, "john@nowhere.com")
    stub_git_log_and_user
    @processor.process_push_from_commit_summary "a9934c1d3a56edfa8f45e5f157869874c8dc2c34 33f746e21ef5122511a5a69f381bfdf017f4d66c refs/heads/foo_branch"
    @processor.repository = Repository.first
    first_event = @processor.events.first
    assert_equal users(:johan).email, first_event.email
    assert_equal(3, first_event.commits.size)
    assert_nil first_event.commits.first.email
    assert_equal users(:johan), first_event.commits.first.user
  end
  
  should "creates commit events even if the committer is unknown" do
    stub_git_log_and_user
    @processor.repository = Repository.first
    @processor.process_push_from_commit_summary '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/heads/master'
    assert_equal :create, @processor.action
    assert_equal 4, @processor.events.size
    assert_equal users(:johan), @processor.events.first.user
    @processor.events[1..4].each do |e|
      assert_equal 'john@nowhere.com', e.email
    end
  end

  should "pick the correct merge request to push to" do
    @merge_request = merge_requests(:moes_to_johans)
    MergeRequest.expects(:find_by_sequence_number!).with(@merge_request.to_param).returns(@merge_request)
    @processor.repository = @merge_request.target_repository
    @processor.expects(:action).returns(:update)
    @processor.expects(:target).returns(:review)
    @processor.stubs(:identifier).returns(@merge_request.to_param)
    @merge_request.expects(:update_from_push!)
    @processor.process_push
  end
  
  should "returns the correct type and identifier for the deletion of a tag" do
    stub_git_show
    @processor.process_push_from_commit_summary "a9934c1d3a56edfa8f45e5f157869874c8dc2c34 0000000000000000000000000000000000000000 refs/tags/r1.1"
    assert_equal :delete, @processor.action
    assert @processor.tag?
    assert_equal 1, @processor.events.size
    assert_equal Action::DELETE_TAG, @processor.events.first.event_type
    assert_equal 'r1.1', @processor.events.first.identifier
    assert_equal 'john@nowhere.com', @processor.events.first.email
    assert_equal 'Deleted tag r1.1', @processor.events.first.message
    @processor.expects(:log_event).once
    @processor.log_events
  end
  
  should "returns the correct type and identifier for the deletion of a branch" do
    stub_git_show
    frozen_now = Time.now
    Time.expects(:now).returns(frozen_now)
    @processor.process_push_from_commit_summary 'a9934c1d3a56edfa8f45e5f157869874c8dc2c34 0000000000000000000000000000000000000000 refs/heads/foo_branch'
    assert_equal :delete, @processor.action
    assert @processor.head?
    assert_equal 1, @processor.events.size
    assert_equal Action::DELETE_BRANCH, @processor.events.first.event_type
    assert_equal 'foo_branch', @processor.events.first.identifier
    assert_equal frozen_now.utc, @processor.events.first.commit_time
    @processor.expects(:log_event).once
    @processor.log_events
  end
  
  should "parse the git output correctly in the real world" do
    grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    @processor.stubs(:git).returns(grit.git)
    @processor.stubs(:user).returns(users(:johan))
    
    @processor.process_push_from_commit_summary "2d3acf90f35989df8f262dc50beadc4ee3ae1560 ca8a30f5a7f0f163bbe3b6f0abf18a6c83b0687a refs/heads/master"
    @processor.repository = Repository.first
    assert_equal :update, @processor.action
    assert @processor.head?
    assert_equal 1, @processor.events.size
    first_event = @processor.events.first
    assert_equal Action::PUSH, first_event.event_type
    assert_equal users(:johan).email, first_event.email
    assert_equal(2, first_event.commits.size)
    commit_event = first_event.commits.first
    assert_equal "ca8a30f5a7f0f163bbe3b6f0abf18a6c83b0687a", commit_event.identifier
    assert_equal "Scott Chacon <schacon@gmail.com>", commit_event.email
    assert_equal Time.at(1208561228), commit_event.commit_time
    exp_msg = "added a pure-ruby git library and converted the cat_file commands to use it"
    assert_equal exp_msg, commit_event.message
  end
  
  def stub_git_log_and_user
    git = mock
    output = [
      '33f746e21ef5122511a5a69f381bfdf017f4d66c',
      'john@nowhere.com',
      '1233842115',
      'This is really nice'
    ].join(PushEventProcessor::PUSH_EVENT_GIT_OUTPUT_SEPARATOR_ESCAPED) + "\n"
    git.stubs(:log).returns(output*3)
    @processor.stubs(:git).returns(git)
    @processor.stubs(:user).returns(users(:johan))
  end
  
  def stub_git_show
    git = mock
    output = [
      "a9934c1d3a56edfa8f45e5f157869874c8dc2c34",
      "john@nowhere.com",
      "1233842115",
      "Whoops, deleting the tag"
    ].join(PushEventProcessor::PUSH_EVENT_GIT_OUTPUT_SEPARATOR_ESCAPED)
    git.stubs(:show).returns(output)
    @processor.stubs(:git).returns(git)    
  end

  context "Generating commit summaries for web hooks" do
    setup {
      @processor = PushEventProcessor.new
      @processor.user = users(:moe)
      
      @push_event = PushEventProcessor::EventForLogging.new
      @commit_event = PushEventProcessor::EventForLogging.new

      @commit_event.email = "marius@gitorious.org"
      @commit_event.identifier = "ffac"
      @commit_event.commit_time = 1.day.ago
      @commit_event.event_type = Action::COMMIT
      @commit_event.message = "A single commit"
      @commit_event.commit_details = {}
      
      @push_event.commits = [@commit_event]
      
      commit_summary = "000 fff refs/heads/master"
      @processor.parse_git_spec(commit_summary)
      @repository = repositories(:johans)
      @processor.repository = @repository
    }

    should "calculate the correct refs" do
      assert_equal "000", @processor.oldrev
      assert_equal "fff", @processor.newrev
      assert_equal "refs/heads/master", @processor.revname
    end

    should "not trigger any hooks if repository has none" do
      @processor.expects(:trigger_hook).never
      @processor.trigger_hooks(Array(@push_event))
    end

    should "trigger hook for each event" do
      @repository.hooks.create(:user => @processor.user, :url => "http://postbin.org/")
      @processor.expects(:trigger_hook).once
      @processor.trigger_hooks(Array(@push_event))
    end

    should "trigger payload generation" do
      @processor.expects(:generate_hook_payload)
      @processor.trigger_hook(@push_event)
    end

    should "generate the correct payload" do
      result = @processor.generate_hook_payload(@push_event)
      assert_not_nil result[:ref]
      assert_not_nil result[:after]
      assert_not_nil result[:before]
      assert_not_nil result[:commits]
      assert_not_nil result[:repository][:url]
    end
  end

  
  # describe 'with stubbing towards a live repo' do
  #   before(:each) do
  #     @repo = Grit::Repo.new("/Users/marius/tmp/clone")
  #     @processor.stubs(:git).returns(@repo.git)
  #   end
  #   
  #   it 'should get decent output from git log' do
  #     @processor.process_push_from_commit_summary "b808ca5eb8ab40a9fdc3489f9f83f6cf6e726a61 abf17983b01f716f34ee10b3f74f14fe7f3bf4ed refs/heads/master"
  #     assert_equal 1, @processor.events.size
  #     assert_equal 'marius.mathiesen@gmail.com', @processor.events.first.email
  #     assert_equal 'Adding some stuff', @processor.events.first.message
  #   end
  # end
end
