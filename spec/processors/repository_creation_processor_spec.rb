#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Marius Mathiesen <marius.mathiesen@gmail.com>
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

describe RepositoryCreationProcessor do
  before(:each) do
    @processor = RepositoryCreationProcessor.new    
    @repository = repositories(:johans)
    
    @clone = mock
    @clone.stubs(:id).returns(99)
    @clone.stubs(:ready).returns(true)
    @clone.expects(:ready=).once.returns(true)
    @clone.expects(:save!).once
    Repository.stubs(:find_by_id).returns(@clone)
    
  end
  
  it "supplies two repos when cloning an existing repository" do
    Repository.expects(:clone_git_repository).with('foo', 'bar')
    message = ActiveSupport::JSON.encode({
      :target_class => 'Repository', 
      :target_id => @clone.id, 
      :command => 'clone_git_repository', 
      :arguments => ['foo', 'bar']})
    @processor.on_message(message)
  end
  
  it 'supplies one repo when creating a new repo' do
    Repository.expects(:create_git_repository).with('foo')
    
    message = ActiveSupport::JSON.encode({
      :target_class => 'Repository', 
      :target_id => @clone.id, 
      :command => 'create_git_repository', 
      :arguments => ['foo']})
    @processor.on_message(message)
  end
  
  after(:each) do
    @processor = nil
  end
end
