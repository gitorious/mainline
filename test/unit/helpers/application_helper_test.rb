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


require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < ActionView::TestCase
  
  should "renders a message if an object is not ready?" do
    repos = repositories(:johans)
    assert build_notice_for(repos).include?("This repository is being created")
  end
  
  should "renders block content if object is ready" do
    obj = mock("any given object")
    obj.stubs(:ready?).returns(true)
    assert_equal "moo", render_if_ready(obj){ "moo" }
  end
  
  should "not render block content if object is ready" do
    obj = mock("any given object")
    obj.stubs(:ready?).returns(false)
    render_if_ready(obj) do
      "moo"
    end
    assert_not_equal "moo", output_buffer
    assert_match(/is being created/, output_buffer)
  end
  
  should "gives us the domain of a full url" do
    assert_equal "foo.com", base_url("http://foo.com")
    assert_equal "www.foo.com", base_url("http://www.foo.com")
    assert_equal "foo.bar.baz.com", base_url("http://foo.bar.baz.com")
    assert_equal "foo.com", base_url("http://foo.com/")
    assert_equal "foo.com", base_url("http://foo.com/bar/baz")
  end
  
  should_eventually "generates a valid gravatar url" do
    # FIXME: Need to be able to deal with the request object from helper tests
    email = "someone@myemail.com";
    url = gravatar_url_for(email)
    
    assert_equal "www.gravatar.com", base_url(url)
    assert url.include?(Digest::MD5.hexdigest(email)), 'url.include?(Digest::MD5.hexdigest(email)) should be true'
    assert url.include?("avatar.php?"), 'url.include?("avatar.php?") should be true'
  end
  
    
  should "render correct css classes for filenames" do
    assert_equal 'ruby-file', class_for_filename('foo.rb')
    assert_equal 'cplusplus-file', class_for_filename('main.cpp')
  end

  context "to_utf8" do
    if RUBY_VERSION > '1.9'
      should "replace unknown chars with a question mark" do
        s = "S\xFCd"
        assert_equal "S?d", force_utf8(s)
      end
      
      should "not replace valid utf chars" do
        s = "Süd"
        assert_equal "Süd", force_utf8(s)
      end
    end
  end
end
