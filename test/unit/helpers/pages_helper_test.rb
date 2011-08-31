# encoding: utf-8
#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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
require 'test_helper'

class PagesHelperTest < ActionView::TestCase
  include PagesHelper

  context "White-listing of specific tags" do
    should "allow a table" do
      html = "<table><tr><td>Yo!</td></tr></table>"
      assert_equal(html, sanitize_wiki_content(html))
    end

    should "remove non-allowed tags from content" do
      good_html = "<table><tr><td>Hey!</td></tr></table>"
      bad_html = good_html + "<script>alert('Yikes!')</script>"
      assert_equal good_html, sanitize_wiki_content(bad_html)
    end
  end

  context "attributes" do
    should "render ids on headings to enable the toc" do
      html = "<h2 id=\"hey\">Hey</h2>"

      assert_equal html, sanitize_wiki_content(html)
    end

    should "render href on links" do
      html = "<a href=\"/home\">Hey</h2>"

      assert_equal html, sanitize_wiki_content(html)
    end

    should "render images" do
      html = "<img src=\"foo.png\">"

      assert_equal html, sanitize_wiki_content(html)
    end
  end
end
