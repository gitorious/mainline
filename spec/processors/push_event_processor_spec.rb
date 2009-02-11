#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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

require File.dirname(__FILE__) + '/../spec_helper'

describe PushEventProcessor do
  before(:each) do
    @processor = PushEventProcessor.new    
  end
  
  it 'returns the correct type and identifier for a new tag' do
    stub_git_show
    @processor.commit_summary = "0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/tags/r1.1"
    @processor.action.should == :create
    @processor.should be_tag
    @processor.events.size.should == 1
    @processor.events.first.event_type.should == Action::CREATE_TAG
    @processor.events.first.identifier.should == 'r1.1'
    @processor.expects(:log_event).once
    @processor.log_events
  end
  
  it 'returns the correct type and identifier for a new branch' do
    stub_git_log_and_user
    @processor.commit_summary = '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/heads/foo_branch'
    @processor.repository = Repository.first
    @processor.action.should == :create
    @processor.should be_head
    @processor.events.size.should == 4
    @processor.events.first.event_type.should == Action::CREATE_BRANCH
    @processor.events.first.identifier.should == 'foo_branch'
    @processor.events[1].event_type.should == Action::COMMIT
    @processor.expects(:log_event).times(4)
    @processor.log_events    
  end
  
  it 'returns the correct type and a set of events for a commit' do
    stub_git_log_and_user
    @processor.commit_summary = "a9934c1d3a56edfa8f45e5f157869874c8dc2c34 33f746e21ef5122511a5a69f381bfdf017f4d66c refs/heads/foo_branch"
    @processor.action.should == :update
    @processor.should be_head
    @processor.events.size.should == 4
    first_event = @processor.events.first
    first_event.event_type.should == Action::PUSH
    first_event.email.should == users(:johan).email
    @processor.expects(:log_event).times(4)
    @processor.log_events
  end
  
  it 'creates commit events even if the committer is unknown' do
    stub_git_log_and_user
    @processor.repository = Repository.first
    @processor.commit_summary = '0000000000000000000000000000000000000000 a9934c1d3a56edfa8f45e5f157869874c8dc2c34 refs/heads/foo_branch'
    @processor.action.should == :create
    @processor.events.size.should == 4
    @processor.events.first.email.should == 'johan@johansorensen.com'
    @processor.events[1..4].each do |e|
      e.email.should == 'john@nowhere.com'
    end
  end
  
  it 'returns the correct type and identifier for the deletion of a tag' do
    stub_git_show
    @processor.commit_summary = "a9934c1d3a56edfa8f45e5f157869874c8dc2c34 0000000000000000000000000000000000000000 refs/tags/r1.1"
    @processor.action.should == :delete
    @processor.should be_tag
    @processor.events.size.should == 1
    @processor.events.first.event_type.should == Action::DELETE_TAG
    @processor.events.first.identifier.should == 'r1.1'
    @processor.events.first.email.should == 'john@nowhere.com'
    @processor.events.first.message.should == 'Deleted branch r1.1'
    @processor.expects(:log_event).once
    @processor.log_events
  end
  
  it 'returns the correct type and identifier for the deletion of a branch' do
    stub_git_show
    @processor.commit_summary = 'a9934c1d3a56edfa8f45e5f157869874c8dc2c34 0000000000000000000000000000000000000000 refs/heads/foo_branch'
    @processor.action.should == :delete
    @processor.should be_head
    @processor.events.size.should == 1
    @processor.events.first.event_type.should == Action::DELETE_BRANCH
    @processor.events.first.identifier.should == 'foo_branch'
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
  #     @processor.events.size.should == 1
  #     @processor.events.first.email.should == 'marius.mathiesen@gmail.com'
  #     @processor.events.first.message.should == 'Adding some stuff'
  #   end
  # end
end

