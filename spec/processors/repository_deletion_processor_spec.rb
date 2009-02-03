#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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

describe RepositoryDeletionProcessor do
  before(:each) do
    @processor = RepositoryDeletionProcessor.new    
  end
  
  it "should process deletion of repositories" do
    Repository.expects('delete_git_repository').with('foo')
    message = ActiveSupport::JSON.encode({:arguments => ['foo']})
    @processor.on_message(message)
  end
  
  after(:each) do
    @processor = nil
  end
end
