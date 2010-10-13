# encoding: utf-8
#--
#   Copyright (C) 2009 Johan Sørensen
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

class MarkupRendererTest < ActiveSupport::TestCase

  context "rendering markdown" do
    should "render standard markdown" do
      text = "foo\n\n**bar**\n\n> baz"
      r = MarkupRenderer.new(text)
      assert_equal r.to_html, RDiscount.new(text).to_html
    end
  end

  context "pre processing" do
    should "turn a single newline into a br" do
      r = MarkupRenderer.new("foo\nbar")
      assert_equal "foo  \nbar", r.pre_process
      assert_equal "<p>foo  <br/>\nbar</p>\n", r.to_html
    end

    should "not both with multiple newlines" do
      r = MarkupRenderer.new("foo\n\nbar")
      assert_equal "<p>foo</p>\n\n<p>bar</p>\n", r.to_html
    end

    should "convert windows lineendings" do
      r = MarkupRenderer.new("foo\r\nbar")
      assert_equal "foo  \nbar", r.pre_process
    end

    should "not touch code blocks, built with html tags" do
      r = MarkupRenderer.new("foo\n<pre><code>if (true)\n  return false</code></pre>")
      exp = "<p>foo<br/>\n<pre><code>if (true)\n  return false</code></pre></p>\n"
      assert_equal exp, r.to_html
    end

    should "not touch code block, built with indentation" do
      r = MarkupRenderer.new("foo\n    if (true)\n      return false")
      exp = "<p>foo<br/>\n</p>\n\n<pre><code>if (true)\n  return false\n</code></pre>\n"
      assert_equal exp, r.to_html
    end

    should "wrap a multi line block in newlines" do
      r = MarkupRenderer.new("foo\nbar\nbaz\nqux")
      assert_equal "<p>foo<br/>\nbar<br/>\nbaz<br/>\nqux</p>\n", r.to_html
    end
  end

  context "post processing" do
    should "wrap the results in a div with a class if :wrap option is true" do
      r = MarkupRenderer.new("foo", :wrapper => true)
      assert_equal "<div class=\"markdown-wrapper\">\n<p>foo</p>\n</div>\n", r.to_html
    end

    should "wrap the results in a div with the given classname in :wrap" do
      r = MarkupRenderer.new("foo", :wrapper => "myclass")
      expected = "<div class=\"myclass markdown-wrapper\">\n<p>foo</p>\n</div>\n"
      assert_equal expected, r.to_html
    end
  end

  context "markdown accessor" do
    should "return the RDiscount instance" do
      rd = MarkupRenderer.new("foo")
      rd.to_html
      assert_instance_of RDiscount, rd.markdown
    end

    should "raise if to_html has not been called yet" do
      rd = MarkupRenderer.new("foo")
      assert_raises(MarkupRenderer::NotProcessedYetError) do
        rd.markdown
      end
    end
  end
end
