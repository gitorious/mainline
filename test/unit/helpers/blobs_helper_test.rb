# encoding: utf-8
#--
#   Copyright (C) 2008-2009 Johan Sørensen <johan@johansorensen.com>
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


require File.dirname(__FILE__) + '/../../test_helper'

class BlobsHelperTest < ActionView::TestCase
  
  def included_modules
    (class << self; self; end).send(:included_modules)
  end
  
  should "includes the RepostoriesHelper" do
    assert included_modules.include?(RepositoriesHelper)
  end
  
  should "includes the TreesHelper" do
    assert included_modules.include?(TreesHelper)
  end  
  
  context "line_numbers_for" do
    should "renders something with line numbers" do
      numbered = line_numbers_for("foo\nbar\nbaz")
      assert numbered.include?(%Q{<td class="line-numbers"><a href="#line2" name="line2">2</a></td>})
      assert numbered.include?(%Q{<td class="code">bar</td>})
    end
  
    should "renders one line with line numbers" do
      numbered = line_numbers_for("foo")
      assert numbered.include?(%Q{<td class="line-numbers"><a href="#line1" name="line1">1</a></td>})
      assert numbered.include?(%Q{<td class="code">foo</td>})
    end
  
    should "doesn't blow up when with_line_numbers receives nil" do
      assert_nothing_raised do
        assert_equal %Q{<table id="codeblob" class="highlighted">\n</table>}, line_numbers_for(nil)
      end
    end
  end
  
  context "render_highlighted()" do
    should "tries to figure out the filetype" do
      Uv.expects(:syntax_names_for_data).with("foo.rb", "puts 'foo'").returns(["ruby"])
      render_highlighted("puts 'foo'", "foo.rb")
    end
    
    should "parses the text" do
      Uv.expects(:syntax_names_for_data).with("foo.rb", "puts 'foo'").returns(["ruby"])
      Uv.expects(:parse).returns("puts 'foo'")
      render_highlighted("puts 'foo'", "foo.rb")
    end
    
    should "adds linenumbers" do
      expects(:line_numbers_for).returns(123)
      render_highlighted("puts 'foo'", "foo.rb")
    end
  end
  
  context "too_big_to_render" do
    should "knows when a blob is too big to be rendered within reasonable time" do
      assert !too_big_to_render?(1.kilobyte)
      assert too_big_to_render?(150.kilobyte+1)
    end
  end
  
end
