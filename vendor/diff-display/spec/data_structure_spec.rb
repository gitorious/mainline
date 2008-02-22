require File.dirname(__FILE__) + '/spec_helper.rb'

describe "Diff::Display data structures" do
  
  describe "Data" do
    it "behaves like an array" do
      data = Diff::Display::Data.new
      data << "foo"
      data.push "bar"
      data.should == ["foo", "bar"]
    end
  end
  
  describe "Line" do
    it "initializes with an old line number" do
      line = Diff::Display::Line.new("foo", 12)
      line.old_number.should == 12
    end

    it "initializes with numbers" do
      line = Diff::Display::Line.new("foo", 12, 13)
      line.old_number.should == 12
      line.new_number.should == 13
    end
    
    it "has a class method for creating an AddLine" do
      line = Diff::Display::Line.add("foo", 7)
      line.should be_instance_of(Diff::Display::AddLine)
    end
    
    it "has a class method for creating a RemLine" do
      line = Diff::Display::Line.rem("foo", 7)
      line.should be_instance_of(Diff::Display::RemLine)
    end
    
    it "has a class method for creating a UnModLine" do
      line = Diff::Display::Line.unmod("foo", 7, 8)
      line.should be_instance_of(Diff::Display::UnModLine)
    end
    
    it "has a class method for creating a HeaderLine" do
      line = Diff::Display::Line.header("foo")
      line.should be_instance_of(Diff::Display::HeaderLine)
    end
  end
  
  describe "Block" do
    it "behaves like an array" do
      block = Diff::Display::Block.new
      block.push 1,2,3
      block.size.should == 3
      block.should == [1,2,3]
    end
    
    it "has class method for creating an AddBlock" do
      block = Diff::Display::Block.add
      block.should be_instance_of(Diff::Display::AddBlock)
    end
    
    it "has class method for creating an RemBlock" do
      block = Diff::Display::Block.rem
      block.should be_instance_of(Diff::Display::RemBlock)
    end
    
    it "has class method for creating an ModBlock" do
      block = Diff::Display::Block.mod
      block.should be_instance_of(Diff::Display::ModBlock)
    end
    
    it "has class method for creating an UnModBlock" do
      block = Diff::Display::Block.unmod
      block.should be_instance_of(Diff::Display::UnModBlock)
    end
    
    it "has class method for creating an HeaderBlock" do
      block = Diff::Display::Block.header
      block.should be_instance_of(Diff::Display::HeaderBlock)
    end
  end
  
end
