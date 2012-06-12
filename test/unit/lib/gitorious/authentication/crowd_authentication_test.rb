# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
require "net/http"
require "rexml/document"

class Gitorious::Authentication::ConfigurationTest < ActiveSupport::TestCase
  def valid_crowd_client(options = {})
    options = options.merge({"application" => "gitorious", "password" => "12345678"})
    Gitorious::Authentication::CrowdAuthentication.new(options)
  end
  def valid_client_credentials(username, password)
    credentials = Gitorious::Authentication::Credentials.new
    credentials.username = username
    credentials.password = password
    credentials
  end

  context "Configuration" do
    should "require an application name" do
      assert_raises Gitorious::Authentication::ConfigurationError do
        crowd = Gitorious::Authentication::CrowdAuthentication.new({})
      end
    end

    should "require an application password" do
      assert_raises Gitorious::Authentication::ConfigurationError do
        crowd = Gitorious::Authentication::CrowdAuthentication.new({"application" => "gitorious"})
      end
    end
  end

  class MockHTTPResponse
    attr_accessor :code

    def initialize(code = "200")
      @code = code
    end
  end

  class MockHTTPConnection
    attr_accessor :use_ssl, :verify_mode, :expected_user, :expected_url

    def initialize(options = {})
      @use_ssl = options.key?(:use_ssl) ? options[:use_ssl] : false
      @verify_mode = nil
      @expected_user = options[:expected_user] || "moe"
      @expected_url = "/crowd/rest/usermanagement/1/authentication?username=#{expected_user}"
    end

    def start
      yield self
    end

    def request(req)
      raise "Unexpected HTTP method POST" if req.method != "POST"
      raise "Unexpected url #{req.path} (#{expected_url})" if req.path != expected_url

      auth = REXML::Document.new(req.body)

      if auth.root.get_elements("value")[0].get_text != "LetMe1n"
        return [MockHTTPResponse.new("400"), invalid_response_body]
      end

      [MockHTTPResponse.new("200"),
       valid_response_body(expected_user, "Moe", "Szyslak", "moe@gitorious.org")]
    end

    def username(req)
      /username=(.*)/.match(req.path)[1]
    end

    def invalid_response_body
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
        "<error><reason>INVALID_USER_AUTHENTICATION</reason>" +
        "<message>Failed to authenticate principal, password was invalid</message></error>"
    end

    def valid_response_body(username, firstname, lastname, email)
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
        "<user name=\"#{username}\" expand=\"attributes\"><link rel=\"self\" " +
        "href=\"http://localhost:8095/crowd/rest/usermanagement/1/user?username=#{username}\"/>" +
        "<first-name>#{firstname}</first-name>" +
        "<last-name>#{lastname}</last-name>" +
        "<display-name>#{firstname} #{lastname}</display-name>" +
        "<email>#{email}</email>" +
        "<password><link rel=\"edit\" " +
        "href=\"http://localhost:8095/crowd/rest/usermanagement/1/user/password?username=christian\"/>" +
        "</password><active>true</active>" +
        "<attributes><link rel=\"self\" " +
        "href=\"http://localhost:8095/crowd/rest/usermanagement/1/user/attribute?username=christian\"/>" +
        "</attributes></user>"
    end

    def use_ssl?
      @use_ssl
    end
  end

  context "Authentication" do
    setup do
      @crowd = valid_crowd_client("context" => "/crowd")
      connection = MockHTTPConnection.new
      Net::HTTP.expects(:new).with("localhost", 8095).returns(connection)
    end

    should "not accept invalid credentials" do
      assert !@crowd.authenticate(valid_client_credentials("moe", "secret"))
    end

    should "accept valid credentials" do
      assert @crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))
    end

    should "return the actual user" do
      assert_equal(users(:moe), @crowd.authenticate(valid_client_credentials("moe", "LetMe1n")))
    end
  end

  context "Authentication connection" do
    should "use ssl" do
      crowd = valid_crowd_client("port" => 443, "context" => "/crowd")
      connection = MockHTTPConnection.new(:use_ssl => true)
      Net::HTTP.expects(:new).with("localhost", 443).returns(connection)

      crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))

      assert connection.use_ssl?
    end

    should "not use ssl by default" do
      crowd = valid_crowd_client("context" => "/crowd")
      connection = MockHTTPConnection.new(:use_ssl => true)
      Net::HTTP.expects(:new).with("localhost", 8095).returns(connection)

      crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))

      assert !connection.use_ssl?
    end

    should "skip ssl verification if configured to do so" do
      crowd = valid_crowd_client("port" => 443, "context" => "/crowd",
                                 "disable_ssl_verification" => true)
      connection = MockHTTPConnection.new(:use_ssl => true)
      Net::HTTP.expects(:new).with("localhost", 443).returns(connection)

      crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))

      assert_equal connection.verify_mode, OpenSSL::SSL::VERIFY_NONE
    end

    should "not skip ssl verification by default" do
      crowd = valid_crowd_client("port" => 443, "context" => "/crowd")
      connection = MockHTTPConnection.new(:use_ssl => true)
      Net::HTTP.expects(:new).with("localhost", 443).returns(connection)

      crowd.authenticate(valid_client_credentials("moe", "LetMe1n"))

      assert_not_equal connection.verify_mode, OpenSSL::SSL::VERIFY_NONE
    end

    should "make request to differen host/port/context" do
      crowd = valid_crowd_client("host" => "sso.myplace", "port" => 80)
      connection = MockHTTPConnection.new(:expected_user => "mooey")
      connection.expected_url = "/rest/usermanagement/1/authentication?username=mooey"
      Net::HTTP.expects(:new).with("sso.myplace", 80).returns(connection)

      crowd.authenticate(valid_client_credentials("mooey", "LetMe1n"))
    end
  end

  context "Auto-registration" do
    setup do
      @crowd = valid_crowd_client("context" => "/crowd")
    end

    should "create a new user with attributes mapped from Crowd" do
      connection = MockHTTPConnection.new(:expected_user => "moe-szyslak")
      Net::HTTP.expects(:new).with("localhost", 8095).returns(connection)

      user = @crowd.authenticate(valid_client_credentials("moe-szyslak", "LetMe1n"))
      assert_equal "moe@gitorious.org", user.email
      assert_equal "Moe Szyslak", user.fullname
      assert_equal "moe-szyslak", user.login

      assert user.valid?
    end

    should "transform user's login to not contain dots" do
      connection = MockHTTPConnection.new(:expected_user => "mr.moe.szyslak")
      Net::HTTP.expects(:new).with("localhost", 8095).returns(connection)

      user = @crowd.authenticate(valid_client_credentials("mr.moe.szyslak", "LetMe1n"))

      assert_equal "mr-moe-szyslak", user.login
    end
  end
end
