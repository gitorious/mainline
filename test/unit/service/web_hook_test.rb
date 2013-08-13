# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class Service::WebHookTest < ActiveSupport::TestCase
  context "url validations" do
    should "validate presence of url" do
      assert Service::WebHook.new(:url => "http://foo").valid?
      refute Service::WebHook.new(:url => "").valid?
      refute Service::WebHook.new(:url => nil).valid?
    end

    should "validate format of url" do
      refute Service::WebHook.new(:url => "http").valid?
      refute Service::WebHook.new(:url => "http://").valid?
      assert Service::WebHook.new(:url => "https://somewhere.com").valid?
      assert Service::WebHook.new(:url => "http://somewhere.com").valid?
      assert Service::WebHook.new(:url => "http://somewhere.com:897/somehere").valid?
    end
  end

  context "#notify" do
    should "send payload to configured url as a form" do
      web_hook = Service::WebHook.new(:url => "http://foo")
      http_client = mock
      http_client.expects(:post).with("http://foo", :form_data => { :payload => '{"foo":123}' })

      web_hook.notify(http_client, :foo => 123)
    end
  end

  should "return a service type" do
    assert_equal "web_hook", Service::WebHook.service_type
  end
end
