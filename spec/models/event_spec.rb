require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  before(:each) do
    @event = new_event
  end
  
  def new_event(opts={})
    c = Event.new({
      :repository => repositories(:johans),
      
      :date => Time.now,
      :body => "blabla"
    }.merge(opts))
    c.user = opts[:user] || users(:johan)
    c
  end
  
  it "should have valid associations" do
    @event.should have_valid_associations
  end
  
  it "should create an event from the action name" do
    event = Event.from_action_name("create project", users(:johan), repositories(:johans))
    event.should_not == nil
  end
  
  it "should not create an event without a valid name" do
    event = Event.from_action_name("invalid action", users(:johan), repositories(:johans))
    event.should == nil
  end
  
  
end

