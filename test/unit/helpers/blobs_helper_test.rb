# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
  
  context "render_highlighted()" do
    should "html escape the line & add the proper class" do
      res = render_highlighted("puts '<foo>'", "foo.rb")
      assert res.include?(%Q{<td class="code"><pre class="prettyprint lang-rb">puts '&lt;foo&gt;'</pre></td>}), res
    end
    
    should "add line numbers" do
      res = render_highlighted("alert('moo')\nalert('moo')", "foo.js")
      assert res.include?(%Q{<td class="line-numbers"><a href="#line2" name="line2">2</a></td>} ), res
    end
  end
  
  context "too_big_to_render" do
    should "knows when a blob is too big to be rendered within reasonable time" do
      assert !too_big_to_render?(1.kilobyte)
      assert too_big_to_render?(350.kilobyte+1)
    end
  end
  
  context "ascii/binary detection" do
    should "know that a plain text file is fine" do
      assert textual?(blob_with_name("foo.txt"))
    end
    
    should "know that a ruby and python file is fine" do
      assert textual?(blob_with_name("foo.rb"))
      assert textual?(blob_with_name("foo.py"))
      assert textual?(blob_with_name("foo.c"))
      assert textual?(blob_with_name("foo.h"))
      assert textual?(blob_with_name("foo.cpp"))
      assert textual?(blob_with_name("foo.m"))
    end
    
    should "know that binary aren't ok" do
      assert !textual?(blob_with_name("foo.png"))
      assert !textual?(blob_with_name("foo.gif"))
      assert !textual?(blob_with_name("foo.exe"))
      
      assert image?(blob_with_name("foo.png"))
      assert image?(blob_with_name("foo.gif"))
      assert !image?(blob_with_name("foo.exe"))
    end
  end
  
  context "highlightable?" do
    should "be highlightable if it's codeish" do
      assert highlightable?(blob_with_name("foo.rb"))
      assert highlightable?(blob_with_name("foo.c"))
      assert highlightable?(blob_with_name("foo.h"))
      assert highlightable?(blob_with_name("foo.py"))
      assert highlightable?(blob_with_name("foo.css"))
    end
    
    should "not be highlightable if there's not file name extension" do
      assert !highlightable?(blob_with_name("README"))
    end
    
    should "not be highlightable if it's a plaintext file" do
      assert !highlightable?(blob_with_name("info.txt"))
      assert !highlightable?(blob_with_name("info.textile"))
    end
  end
  
  def blob_with_name(name)
    repo = mock("grit repo")
    Grit::Blob.create(repo, {:name => name})
  end
  
end
