#--
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
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

describe Task do
  before(:each) do
    @task = tasks(:create_repo)
  end

  it "has_valid_associations" do
    @task.should have_valid_associations
  end
  
  it "performs a task" do
    @task.target_class.constantize.should_receive(@task.command) \
      .with(*@task.arguments).and_return(true)
    @task.perform!
    @task.reload
    @task.performed?.should == true
    @task.performed_at.should_not == nil
  end
  
  it "marks the object as ready if it has a target_id" do
    target = repositories(:johans)
    target.ready = false
    target.save!
    @task.target_id = target.id
    @task.target_class.constantize.should_receive(@task.command) \
      .with(*@task.arguments).and_return(true)
    @task.perform!
    target.reload.ready?.should == true
  end
  
  it "finds tasks that needs performin'" do
    @task.update_attributes(:performed => true)
    Task.find_all_pending.should == [tasks(:add_key)]
  end
  
  it "performs all pending tasks" do
    to_perform = tasks(:create_repo, :add_key)
    Task.should_receive(:find_all_pending).and_return(to_perform)
    to_perform.each do |task|
      task.should_receive(:perform!).and_return(true)
    end
    Task.perform_all_pending!
  end
end
