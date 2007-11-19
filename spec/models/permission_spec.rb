require File.dirname(__FILE__) + '/../spec_helper'

describe Permission do
  before(:each) do
    @permission = Permission.new
  end

  it "should be valid" do
    @permission.should be_valid
  end
end
