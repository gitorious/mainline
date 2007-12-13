require File.dirname(__FILE__) + '/../spec_helper'

describe Committership do
  before(:each) do
    @committership = Committership.new
  end

  it "should be valid" do
    @committership.should be_valid
  end
end
