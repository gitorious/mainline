require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Diff::Renderer::Base do
  
  before(:each) do
    @data = Diff::Display::Unified::Generator.run(load_diff("big"))
    @base_renderer = Diff::Renderer::Base.new
  end
  
  it "classifies a classname" do
    @base_renderer.send(:classify, Diff::Display::RemBlock.new).should == "remblock"
  end
  
  it "calls the before_headerblock" do
    @base_renderer.expects(:before_headerblock).at_least_once
    @base_renderer.render(@data)
  end
  
  # it "calls the before_sepblock" do
  #   @base_renderer.expects(:before_sepblock).at_least_once
  #   @base_renderer.render(@data)
  # end
  
  # it "calls the before_modblock" do
  #   @base_renderer.expects(:before_modblock).at_least_once
  #   @base_renderer.render(@data)
  # end
  
  it "calls the before_unmodblock" do
    @base_renderer.expects(:before_unmodblock).at_least_once
    @base_renderer.render(@data)
  end
  
  it "calls the before_addblock" do
    @base_renderer.expects(:before_addblock).at_least_once
    @base_renderer.render(@data)
  end
  
  it "calls the before_remblock" do
    @base_renderer.expects(:before_remblock).at_least_once
    @base_renderer.render(@data)
  end
  
  it "calls headerline" do
    @base_renderer.expects(:headerline).at_least_once
    @base_renderer.render(@data)
  end
  
  it "calls unmodline" do
    @base_renderer.expects(:unmodline).at_least_once
    @base_renderer.render(@data)
  end  
  
  it "calls addline" do
    @base_renderer.expects(:addline).at_least_once
    @base_renderer.render(@data)
  end
  
  it "calls remline" do
    @base_renderer.expects(:remline).at_least_once
    @base_renderer.render(@data)
  end
  
  it "calls the after_headerblock" do
    @base_renderer.expects(:after_headerblock).at_least_once
    @base_renderer.render(@data)
  end
  
  # it "calls the after_sepblock" do
  #   @base_renderer.expects(:after_sepblock).at_least_once
  #   @base_renderer.render(@data)
  # end
  
  # it "calls the after_modblock" do
  #   @base_renderer.expects(:after_modblock).at_least_once
  #   @base_renderer.render(@data)
  # end
  
  it "calls the after_unmodblock" do
    @base_renderer.expects(:after_unmodblock).at_least_once
    @base_renderer.render(@data)
  end
  
  it "calls the after_addblock" do
    @base_renderer.expects(:after_addblock).at_least_once
    @base_renderer.render(@data)
  end
  
  it "calls the after_remblock" do
    @base_renderer.expects(:after_remblock).at_least_once
    @base_renderer.render(@data)
  end
  
  it "renders a basic datastructure" do
    output = @base_renderer.render(@data)
    output.should_not == nil
  end
end