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

class TestEnv
  attr_accessor :request
  include ApplicationHelper

  def u(str)
    str
  end
end

class ApplicationHelperTest < ActionView::TestCase
  def setup
    @env = TestEnv.new
    @env.request = stub("request")
  end

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

  should "generate a valid gravatar url" do
    @env.request.stubs(:ssl?).returns(false)
    @env.request.stubs(:port).returns(80)

    email = "someone@myemail.com";
    url = @env.gravatar_url_for(email)

    assert_equal "www.gravatar.com", base_url(url)
    assert url.include?(Digest::MD5.hexdigest(email)), 'url.include?(Digest::MD5.hexdigest(email)) should be true'
    assert url.include?("avatar.php?"), 'url.include?("avatar.php?") should be true'
    assert url.include?("default=http://")
  end

  should "generate a valid gravatar url when using https" do
    @env.request.stubs(:ssl?).returns(true)
    @env.request.stubs(:port).returns(443)

    email = "someone@myemail.com";
    url = @env.gravatar_url_for(email)

    assert_match /^https:\/\//, url
    assert_equal "secure.gravatar.com", base_url(url)
    assert url.include?(Digest::MD5.hexdigest(email))
    assert url.include?("default=https://")
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

  context "favicon link tag" do
    setup do
      @gitconf = GitoriousConfig["favicon_url"]
    end

    teardown do
      GitoriousConfig["favicon_url"] = @gitconf
    end

    should "not return markup when no url is configured" do
      GitoriousConfig["favicon_url"] = ""
      assert favicon_link_tag.blank?
    end

    should "return link tag for configured favicon url" do
      GitoriousConfig["favicon_url"] = "http://myserver.com/favicon.ico"
      assert_match "myserver.com/favicon", favicon_link_tag
      assert_match "shortcut", favicon_link_tag
    end

    should "return nothing when no favicon_url setting exists" do
      GitoriousConfig.delete(["favicon_url"])
      assert favicon_link_tag.blank?
    end
  end

  context "logo link tag" do
    setup do
      @gitconf = GitoriousConfig["logo_url"]
    end

    teardown do
      GitoriousConfig["logo_url"] = @gitconf
    end

    should "return linked text when empty url is configured" do
      GitoriousConfig["logo_url"] = ""
      assert_match ">Gitorious<", logo_link
      assert_no_match /img/, logo_link
    end

    should "return linked default logo no url is configured" do
      GitoriousConfig.delete("logo_url")
      assert_match /img[^>]*src=/, logo_link
      assert_match "/img/logo.png", logo_link
    end

    should "return linked configured url" do
      GitoriousConfig["logo_url"] = "http://myserver.com/logo.png"
      assert_match /img[^>]*src=/, logo_link
      assert_match "http://myserver.com/logo.png", logo_link
      assert_no_match /\/img\/logo\.png/, logo_link
    end
  end
end
