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
  
  it 'classifies a commit by type' do
    @processor.commit_summary = "#{'0'*40} #{'a'*40} refs/heads/master"
    @processor.event_type.should == Action::CREATE_BRANCH
    @processor.commit_summary = "#{'b'*40} #{'0'*40} refs/heads/master"
    @processor.event_type.should == Action::DELETE_BRANCH
    @processor.commit_summary = "#{'a'*40} #{'b'*40} refs/heads/master"
    @processor.event_type.should == Action::COMMIT
  end
end