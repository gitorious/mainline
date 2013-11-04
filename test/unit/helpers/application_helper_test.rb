# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

require "test_helper"

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
    output = render_if_ready(obj) do
      "moo"
    end
    assert_not_equal "moo", output
    assert_match(/is being created/, output)
  end

  should "generate a valid gravatar url" do
    @env.request.stubs(:ssl?).returns(false)
    @env.request.stubs(:port).returns(80)

    email = "someone@myemail.com";
    url = @env.gravatar_url_for(email)

    assert url.include?(Digest::MD5.hexdigest(email)), 'url.include?(Digest::MD5.hexdigest(email)) should be true'
    assert url.include?("avatar/"), 'url.include?("avatar/") should be true'
    assert url.include?("default=http://")
  end

  should "generate a valid gravatar url when using https" do
    @env.request.stubs(:ssl?).returns(true)
    @env.request.stubs(:port).returns(443)

    email = "someone@myemail.com";
    url = @env.gravatar_url_for(email)

    assert_match /^https:\/\//, url
    assert url.include?(Digest::MD5.hexdigest(email))
    assert url.include?("default=https://")
  end

  context "logo link tag" do
    should "return linked default logo no url is configured" do
      assert_match /img[^>]*src=/, logo_link
      assert_match "/dist/images/gitorious2013.png", logo_link
    end

    should "return linked text when empty url is configured" do
      Gitorious::Configuration.override("logo_url" => "") do |c|
        assert_match ">Gitorious<", logo_link
        assert_no_match /img/, logo_link
      end
    end

    should "return linked configured url" do
      Gitorious::Configuration.override("logo_url" => "http://myserver.com/logo.png") do |c|
        assert_match /img[^>]*src=/, logo_link
        assert_match "http://myserver.com/logo.png", logo_link
        assert_no_match /\/img\/logo\.png/, logo_link
      end
    end
  end

end
