require File.dirname(__FILE__) + '/spec_helper.rb'

describe "API acceptance specs" do
  
  it "has a simple API" do
    diff = Diff::Display::Unified.new(load_diff("simple"))
    diff.render(Diff::Renderer::Base.new)
  end
  
end