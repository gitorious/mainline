require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  before(:each) do
    @event = new_event
    @user = users(:johan)
    @repository = repositories(:johans)
  end
  
  def new_event(opts={})
    c = Event.new({
      :target => repositories(:johans),
      
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
    @user.create_event(Action::CREATE_PROJECT, @repository, "", "").should_not == nil
  end
  
  it "should create an event even without a valid id" do
    @user.create_event(52342, @repository).should_not == nil
  end
  
  
end

