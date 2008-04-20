require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  before(:each) do
    @event = new_event
    @user = users(:johan)
    @repository = repositories(:johans)
    @project = @repository.project
  end
  
  def new_event(opts={})
    c = Event.new({
      :target => repositories(:johans),
      :body => "blabla"
    }.merge(opts))
    c.user = opts[:user] || users(:johan)
    c.project = opts[:project] || @project
    c
  end
  
  it "should have valid associations" do
    @event.should have_valid_associations
  end  
  
end

