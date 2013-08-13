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
      http_client.expects(:post_form).with("http://foo", :payload => '{"foo":123}')

      web_hook.notify(http_client, :foo => 123)
    end
  end

  should "return a service type" do
    assert_equal "web_hook", Service::WebHook.service_type
  end
end
