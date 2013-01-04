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
require "rexml/document"

module Gitorious
  module SSLTestHelper
    def valid_client_credentials(cn, email)
      # construct a simple Rails request.env hash
      env = Hash.new
      env["SSL_CLIENT_S_DN_CN"] = cn
      env["SSL_CLIENT_S_DN_Email"] = email
      # Wrap this in the G::A::Credentials object.
      credentials = Gitorious::Authentication::Credentials.new
      credentials.env = env
      credentials
    end
  end

  module LDAPTestHelper
    def valid_client_credentials(username, password)
      credentials = Gitorious::Authentication::Credentials.new
      credentials.username = username
      credentials.password = password
      credentials
    end

    class CallbackMock
      def self.reset
        @post_authenticate_called = nil
      end

      def self.post_authenticate(options)
        @post_authenticate_called = :true
      end

      def self.called?
        @post_authenticate_called == :true
      end
    end

    class StaticLDAPConnection
      def initialize(opts)
        raise "Static LDAP connection created without host" unless opts[:host]
      end

      def self.login_attribute=(attr)
        @login_attribute = attr
      end

      def self.login_attribute
        @login_attribute || "CN"
      end

      def self.username=(name)
        @username = name
      end

      def self.username
        @username || "moe"
      end

      def auth(username, password)
        @allowed = username == "#{self.class.login_attribute}=#{self.class.username},DC=gitorious,DC=org" && password == "secret"
      end

      def bind
        @allowed
      end

      def search(options)
        return [] unless /^\(#{login_attribute}=/ =~ options[:filter].to_s
        entry = {"displayname" => ["Moe Szyslak"], "mail" => ["moe@gitorious.org"]}
        entry["mail"] = [] if self.class.never_return_email?
        result = [entry]
        result
      end

      def self.never_return_email?
        @return_empty_email_address
      end

      def self.return_empty_email_address!
        @return_empty_email_address = true
        yield
        @return_empty_email_address = false
      end

      private
      def login_attribute
        self.class.login_attribute
      end
    end
  end

  module KerberosTestHelper
    # Accepts a Kerberos principal string, and returns a
    # Gitorious::Authentication::Credentials object
    def valid_client_credentials(principal)
      # construct a simple Rails request.env hash
      env = Hash.new
      env['HTTP_AUTHORIZATION'] = 'Negotiate ABCDEF123456'
      env['REMOTE_USER'] = principal
      # Wrap this in the G::A::Credentials object.
      credentials = Gitorious::Authentication::Credentials.new
      credentials.env = env
      credentials
    end
  end

  module CrowdTestHelper
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
  end
end
