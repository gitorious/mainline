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
      .with(@task.arguments).and_return(true)
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
      .with(@task.arguments).and_return(true)
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
