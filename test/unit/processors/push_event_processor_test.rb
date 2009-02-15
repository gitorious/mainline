# encoding: utf-8
#--
#   Copyright (C) 2009 Marius Mårnes Mathiesen <marius.mathiesen@gmail.com>
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
  
 should "returns the correct type and identifier for a new tag" do
    stub_git_show
    @processor.commit_summary = "0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/tags/r1.1"
    assert_equal :create, @processor.action
    assert @processor.tag?
    assert_equal 1, @processor.events.size
    assert_equal Action::CREATE_TAG, @processor.events.first.event_type
    assert_equal 'r1.1', @processor.events.first.identifier
    @processor.expects(:log_event).once
    @processor.log_events
  end
  
 should "returns the correct type and identifier for a new branch" do
    stub_git_log_and_user
    @processor.commit_summary = '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/heads/foo_branch'
    @processor.repository = Repository.first
    assert_equal :create, @processor.action
    assert @processor.head?
    assert_equal 4, @processor.events.size
    assert_equal Action::CREATE_BRANCH, @processor.events.first.event_type
    assert_equal 'foo_branch', @processor.events.first.identifier
    assert_equal Action::COMMIT, @processor.events[1].event_type
    @processor.expects(:log_event).times(4)
    @processor.log_events    
  end
  
 should "returns the correct type and a set of events for a commit" do
    stub_git_log_and_user
    @processor.commit_summary = "a9934c1d3a56edfa8f45e5f157869874c8dc2c34 33f746e21ef5122511a5a69f381bfdf017f4d66c refs/heads/foo_branch"
    assert_equal :update, @processor.action
    assert @processor.head?
    assert_equal 4, @processor.events.size
    first_event = @processor.events.first
    assert_equal Action::PUSH, first_event.event_type
    assert_equal users(:johan).email, first_event.email
    @processor.expects(:log_event).times(4)
    @processor.log_events
  end
  
 should "creates commit events even if the committer is unknown" do
    stub_git_log_and_user
    @processor.repository = Repository.first
    @processor.commit_summary = '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/heads/foo_branch'
    assert_equal :create, @processor.action
    assert_equal 4, @processor.events.size
    assert_equal 'johan@johansorensen.com', @processor.events.first.email
    @processor.events[1..4].each do |e|
      assert_equal 'john@nowhere.com', e.email
    end
  end
  
 should "returns the correct type and identifier for the deletion of a tag" do
    stub_git_show
    @processor.commit_summary = "a9934c1d3a56edfa8f45e5f157869874c8dc2c34 0000000000000000000000000000000000000000 refs/tags/r1.1"
    assert_equal :delete, @processor.action
    assert @processor.tag?
    assert_equal 1, @processor.events.size
    assert_equal Action::DELETE_TAG, @processor.events.first.event_type
    assert_equal 'r1.1', @processor.events.first.identifier
    assert_equal 'john@nowhere.com', @processor.events.first.email
    assert_equal 'Deleted branch r1.1', @processor.events.first.message
    @processor.expects(:log_event).once
    @processor.log_events
  end
  
 should "returns the correct type and identifier for the deletion of a branch" do
    stub_git_show
    @processor.commit_summary = 'a9934c1d3a56edfa8f45e5f157869874c8dc2c34 0000000000000000000000000000000000000000 refs/heads/foo_branch'
    assert_equal :delete, @processor.action
    assert @processor.head?
    assert_equal 1, @processor.events.size
    assert_equal Action::DELETE_BRANCH, @processor.events.first.event_type
    assert_equal 'foo_branch', @processor.events.first.identifier
    @processor.expects(:log_event).once
    @processor.log_events
  end
  
  def stub_git_log_and_user
    git = mock
    output = ['33f746e21ef5122511a5a69f381bfdf017f4d66c', 'john@nowhere.com','1233842115','This is really nice'].join(PushEventProcessor::GIT_OUTPUT_SEPARATOR) + "\n"
    git.stubs(:log).returns(output*3)
    @processor.stubs(:git).returns(git)
    @processor.stubs(:user).returns(users(:johan))
  end
  
  def stub_git_show
    git = mock
    output = ["a9934c1d3a56edfa8f45e5f157869874c8dc2c34","john@nowhere.com","1233842115","Whoops, deleting the tag"].join(PushEventProcessor::GIT_OUTPUT_SEPARATOR)
    git.stubs(:show).returns(output)
    @processor.stubs(:git).returns(git)    
  end
  
  # describe 'with stubbing towards a live repo' do
  #   before(:each) do
  #     @repo = Grit::Repo.new("/Users/marius/tmp/clone")
  #     @processor.stubs(:git).returns(@repo.git)
  #   end
  #   
  #   it 'should get decent output from git log' do
  #     @processor.commit_summary = "b808ca5eb8ab40a9fdc3489f9f83f6cf6e726a61 abf17983b01f716f34ee10b3f74f14fe7f3bf4ed refs/heads/master"
  #     assert_equal 1, @processor.events.size
  #     assert_equal 'marius.mathiesen@gmail.com', @processor.events.first.email
  #     assert_equal 'Adding some stuff', @processor.events.first.message
  #   end
  # end
end
