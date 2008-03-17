require File.dirname(__FILE__) + '/../spec_helper'

describe BlobsHelper do
  
  it "includes the RepostoriesHelper" do
    self.class.ancestors.should include(RepositoriesHelper)
  end
  
  it "includes the TreesHelper" do
    self.class.ancestors.should include(TreesHelper)
  end
  
  describe "line_numbers_for" do
    it "renders something with line numbers" do
      numbered = line_numbers_for("foo\nbar\nbaz")
      numbered.should include(%Q{<td class="line-numbers"><a href="#line2" name="line2">2</a></td>})
      numbered.should include(%Q{<td class="code">bar</td>})
    end
  
    it "renders one line with line numbers" do
      numbered = line_numbers_for("foo")
      numbered.should include(%Q{<td class="line-numbers"><a href="#line1" name="line1">1</a></td>})
      numbered.should include(%Q{<td class="code">foo</td>})
    end
  
    it "doesn't blow up when with_line_numbers receives nil" do
      proc{
        line_numbers_for(nil).should == %Q{<table id="codeblob" class="highlighted">\n</table>}
      }.should_not raise_error
    end
  end
  
  describe "render_highlighted()" do
    it "tries to figure out the filetype" do
      Uv.should_receive(:syntax_names_for_data).with("foo.rb", "puts 'foo'").and_return(["ruby"])
      render_highlighted("puts 'foo'", "foo.rb")
    end
    
    it "parses the text" do
      Uv.should_receive(:syntax_names_for_data).with("foo.rb", "puts 'foo'").and_return(["ruby"])
      Uv.should_receive(:parse).and_return("puts 'foo'")
      render_highlighted("puts 'foo'", "foo.rb")
    end
    
    it "adds linenumbers" do
      should_receive(:line_numbers_for).and_return(123)
      render_highlighted("puts 'foo'", "foo.rb")
    end
  end
  
  describe "too_big_to_render" do
    it "knows when a blob is too big to be rendered within reasonable time" do
      too_big_to_render?(1.kilobyte).should == false
      too_big_to_render?(150.kilobyte+1).should == true
    end
  end
  
end
