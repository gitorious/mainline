require File.dirname(__FILE__) + '/../spec_helper'

describe Task do
  before(:each) do
    @task = tasks(:create_repo)
  end

  it "has_valid_associations" do
    @task.should have_valid_associations
  end
  
  it "performs a task" do
    @task.target.should_receive(@task.command).and_return(true)
    @task.perform!
    @task.reload
    @task.performed?.should == true
    @task.performed_at.should_not == nil
  end
  
  it "finds tasks that needs performin'" do
    @task.update_attributes(:performed => true)
    Task.find_all_to_perform.should == [tasks(:add_key)]
  end
end
