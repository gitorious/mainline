# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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
require "fast_test_helper"
require "authentication_test_helper"
require "net/http"
require "gitorious/authentication/configuration"
require "gitorious/authentication/credentials"
require "gitorious/authentication/crowd_authentication"

class Gitorious::Authentication::ConfigurationTest < MiniTest::Spec
  include Gitorious::CrowdTestHelper

  describe "Configuration" do
    it "requires an application name" do
      assert_raises Gitorious::Authentication::ConfigurationError do
        crowd = Gitorious::Authentication::CrowdAuthentication.new({})
      end
    end

    it "requires an application password" do
      assert_raises Gitorious::Authentication::ConfigurationError do
        crowd = Gitorious::Authentication::CrowdAuthentication.new({"application" => "gitorious"})
      end
    end
  end

  describe "Authentication" do
    before do
      @crowd = valid_crowd_client("context" => "/crowd")
      connection = MockHTTPConnection.new
      Net::HTTP.expects(:new).with("localhost", 8095).returns(connection)
    end

    it "does not accept invalid credentials" do
      assert !@crowd.authenticate(valid_client_credentials("moe", "secret"))
    end

    it "accepts valid credentials" do
      assert @crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))
    end

    it "returns the actual user" do
      user = @crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))
      assert_equal("moe", user.login)
    end
  end

  describe "Authentication connection" do
    it "uses ssl" do
      crowd = valid_crowd_client("port" => 443, "context" => "/crowd")
      connection = MockHTTPConnection.new(:use_ssl => true)
      Net::HTTP.expects(:new).with("localhost", 443).returns(connection)

      crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))

      assert connection.use_ssl?
    end

    it "does not use ssl by default" do
      crowd = valid_crowd_client("context" => "/crowd")
      connection = MockHTTPConnection.new(:use_ssl => true)
      Net::HTTP.expects(:new).with("localhost", 8095).returns(connection)

      crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))

      assert !connection.use_ssl?
    end

    it "skips ssl verification if configured to do so" do
      crowd = valid_crowd_client("port" => 443, "context" => "/crowd",
                                 "disable_ssl_verification" => true)
      connection = MockHTTPConnection.new(:use_ssl => true)
      Net::HTTP.expects(:new).with("localhost", 443).returns(connection)

      crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))

      assert_equal connection.verify_mode, OpenSSL::SSL::VERIFY_NONE
    end

    it "does not skip ssl verification by default" do
      crowd = valid_crowd_client("port" => 443, "context" => "/crowd")
      connection = MockHTTPConnection.new(:use_ssl => true)
      Net::HTTP.expects(:new).with("localhost", 443).returns(connection)

      crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))

      refute_equal connection.verify_mode, OpenSSL::SSL::VERIFY_NONE
    end

    it "makes request to differen host/port/context" do
      crowd = valid_crowd_client("host" => "sso.myplace", "port" => 80)
      connection = MockHTTPConnection.new(:expected_user => "mooey")
      connection.expected_url = "/rest/usermanagement/1/authentication?username=mooey"
      Net::HTTP.expects(:new).with("sso.myplace", 80).returns(connection)

      crowd.authenticate(valid_client_credentials("mooey", "LetMe1n"))
    end
  end

  describe "Auto-registration" do
    before do
      @crowd = valid_crowd_client("context" => "/crowd")
    end

    it "transforms user's login to not contain dots" do
      connection = MockHTTPConnection.new(:expected_user => "mr.moe.szyslak")
      Net::HTTP.expects(:new).with("localhost", 8095).returns(connection)

      user = @crowd.authenticate(valid_client_credentials("mr.moe.szyslak", "LetMe1n"))

      assert_equal "mr-moe-szyslak", user.login
    end
  end
end
