require File.dirname(__FILE__) + '/spec_helper.rb'

describe Diff::Display::Unified::Generator do
  
  before(:each) do
    @generator = Diff::Display::Unified::Generator.new
  end
  
  it "Generator.run raises if doesn't get a Enumerable object" do
    proc {
      Diff::Display::Unified::Generator.run(nil)
    }.should raise_error(ArgumentError)
  end
  
  it "Generator.run processes each line in the diff" do
    Diff::Display::Unified::Generator.expects(:new).returns(@generator)
    @generator.expects(:process).with("foo")
    @generator.expects(:process).with("bar")
    Diff::Display::Unified::Generator.run("foo\nbar")
  end
  
  it "Generator.run returns the data" do
    Diff::Display::Unified::Generator.expects(:new).returns(@generator)
    generated = Diff::Display::Unified::Generator.run("foo\nbar")
    generated.should be_instance_of(Diff::Display::Data)
  end
  
  it "the returned that object is in parity with the diff" do
    %w[simple only_add  only_rem multiple_adds_after_rem].each do |diff|
      data = Diff::Display::Unified::Generator.run(load_diff(diff))
      data.to_diff.should == load_diff(diff).chomp
    end
  end
  
  describe "edgecase bugs" do
    it "multiple rems and an add is in parity" do
      diff_data = load_diff("multiple_rems_then_add")
      data = Diff::Display::Unified::Generator.run(diff_data)
      data.to_diff.should == diff_data.chomp
    end
    
    #it "doesn't parse linenumbers that isn't part if the diff" do
    #  line_numbers_for(:pseudo_recursive).compact.should == (1..14).to_a
    #end
  end

  describe "line numbering" do
    it "numbers correctly for multiple_adds_after_rem" do
      line_numbers_for(:multiple_adds_after_rem).should == [
        [193, 193],
        [194, nil],
        [nil, 194],
        [nil, 195],
        [nil, 196],
        [nil, 197],
        [nil, 198],
        [195, 199]
      ]
    end

    it "numbers correctly for simple" do
      line_numbers_for(:simple).should == [
        [1, 1],
        [2, 2],
        [3, nil],
        [4, nil],
        [nil, 3],
        [nil, 4],
        [nil, 5],
      ]
    end
  end

  def line_numbers_for(diff)
    diff_data = load_diff(diff)
    data = Diff::Display::Unified::Generator.run(diff_data)
    linenos = []
    data.each do |blk| 
      blk.each do |line|
        next if line.class == Diff::Display::HeaderLine
        linenos << [line.old_number, line.new_number]
      end
    end
    linenos
  end
end
