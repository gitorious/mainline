#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe BlobsHelper do
  
  include BlobsHelper
  
  def included_modules
    (class << helper; self; end).send(:included_modules)
  end
  
  it "includes the RepostoriesHelper" do
    included_modules.should include(RepositoriesHelper)
  end
  
  it "includes the TreesHelper" do
    included_modules.should include(TreesHelper)
  end  
  
  describe "line_numbers_for" do
    it "renders something with line numbers" do
      numbered = helper.line_numbers_for("foo\nbar\nbaz")
      numbered.should include(%Q{<td class="line-numbers"><a href="#line2" name="line2">2</a></td>})
      numbered.should include(%Q{<td class="code">bar</td>})
    end
  
    it "renders one line with line numbers" do
      numbered = helper.line_numbers_for("foo")
      numbered.should include(%Q{<td class="line-numbers"><a href="#line1" name="line1">1</a></td>})
      numbered.should include(%Q{<td class="code">foo</td>})
    end
  
    it "doesn't blow up when with_line_numbers receives nil" do
      proc{
        helper.line_numbers_for(nil).should == %Q{<table id="codeblob" class="highlighted">\n</table>}
      }.should_not raise_error
    end
  end
  
  describe "render_highlighted()" do
    it "tries to figure out the filetype" do
      Uv.should_receive(:syntax_names_for_data).with("foo.rb", "puts 'foo'").and_return(["ruby"])
      helper.render_highlighted("puts 'foo'", "foo.rb")
    end
    
    it "parses the text" do
      Uv.should_receive(:syntax_names_for_data).with("foo.rb", "puts 'foo'").and_return(["ruby"])
      Uv.should_receive(:parse).and_return("puts 'foo'")
      helper.render_highlighted("puts 'foo'", "foo.rb")
    end
    
    it "adds linenumbers" do
      helper.should_receive(:line_numbers_for).and_return(123)
      helper.render_highlighted("puts 'foo'", "foo.rb")
    end
  end
  
  describe "too_big_to_render" do
    it "knows when a blob is too big to be rendered within reasonable time" do
      helper.too_big_to_render?(1.kilobyte).should == false
      helper.too_big_to_render?(150.kilobyte+1).should == true
    end
  end
  
end
