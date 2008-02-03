require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Diff::Renderer::Diff do
  it "renders a diff back to its original state" do
    data = Diff::Display::Unified::Generator.run(load_diff("simple"))
    base_renderer = Diff::Renderer::Diff.new
    base_renderer.render(data).should == load_diff("simple")
  end
end
