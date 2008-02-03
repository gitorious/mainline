require File.dirname(__FILE__) + '/spec_helper.rb'

describe Diff::Display::Unified do
  
  it "generates its data structure via the Generator" do
    generator_data = mock("Generator mock")
    Diff::Display::Unified::Generator.expects(:run).returns(generator_data)
    diff = Diff::Display::Unified.new(load_diff("simple"))
    diff.data.should == generator_data
  end
  
  it "renders a diff via a callback and renders it to a stringlike object" do
    diff = Diff::Display::Unified.new(load_diff("simple"))
    callback = mock()
    callback.expects(:render).returns("foo")
    output = ""
    diff.render(callback, output)
    output.should == "foo"
  end
  
end