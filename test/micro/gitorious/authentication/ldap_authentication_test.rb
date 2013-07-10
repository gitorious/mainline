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
require "gitorious/authentication/configuration"
require "gitorious/authentication/credentials"
require "gitorious/authentication/ldap_authentication"

class Gitorious::Authentication::LDAPAuthenticationTest < MiniTest::Spec
  # Mock that should receive callbacks
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

  def valid_client_credentials(username, password)
    credentials = Gitorious::Authentication::Credentials.new
    credentials.username = username
    credentials.password = password
    credentials
  end

  describe "Configuration" do
    before do
      @ldap = Gitorious::Authentication::LDAPAuthentication.new({
        "server" => "localhost",
        "base_dn" => "DC=gitorious,DC=org"
      })
    end

    it "requires a server name" do
      assert_raises Gitorious::Authentication::ConfigurationError do
        ldap = Gitorious::Authentication::LDAPAuthentication.new({"base_dn" => "DC=gitorious.DC=org"})
      end
    end

    it "requires a base DN" do
      assert_raises Gitorious::Authentication::ConfigurationError do
        ldap = Gitorious::Authentication::LDAPAuthentication.new({"server" => "localhost"})
      end
    end

    it "uses a default LDAP port" do
      assert_equal 389, @ldap.port
    end

    it "defaults to simple tls encryption" do
      assert_equal :simple_tls, @ldap.encryption
    end

    it "provides a default attribute mapping" do
      assert_equal({"displayname" => "fullname", "mail" => "email"}, @ldap.attribute_mapping)
    end

    it "uses a Net::LDAP instance by default" do
      assert_equal Net::LDAP, @ldap.connection_type
    end

    it "provides a default DN template" do
      assert_equal "CN={},DC=gitorious,DC=org", @ldap.distinguished_name_template
    end

    it "provides default DN template with different login attribute" do
      @ldap = Gitorious::Authentication::LDAPAuthentication.new({
        "server" => "localhost",
        "base_dn" => "dc=gitorious,dc=org",
        "login_attribute" => "uid"
      })

      assert_equal "uid={},dc=gitorious,dc=org", @ldap.distinguished_name_template
    end
  end

  describe "Authentication" do
    before do
      @ldap = Gitorious::Authentication::LDAPAuthentication.new({
        "server" => "localhost",
        "base_dn" => "DC=gitorious,DC=org",
        "connection_type" => Gitorious::LDAPTestHelper::StaticLDAPConnection
      })
    end

    it "does not accept invalid credentials" do
      assert !@ldap.valid_credentials?("moe","LetMe1n")
    end

    it "accepts valid credentials" do
      assert @ldap.valid_credentials?("moe","secret")
    end

    it "returns the actual user" do
      moe = User.new
      User.stubs(:find_by_login).with("moe").returns(moe)
      assert_equal(moe, @ldap.authenticate(valid_client_credentials("moe","secret")))
    end

    it "allows host as alias for server" do
      ldap = Gitorious::Authentication::LDAPAuthentication.new({
        "host" => "localhost",
        "base_dn" => "DC=gitorious,DC=org",
        "connection_type" => Gitorious::LDAPTestHelper::StaticLDAPConnection
      })

      assert ldap.valid_credentials?("moe","secret")
    end
  end

  describe "Callbacks" do
    before do
      @ldap = Gitorious::Authentication::LDAPAuthentication.new({
        "server" => "localhost",
        "base_dn" => "DC=gitorious,DC=org",
        "connection_type" => Gitorious::LDAPTestHelper::StaticLDAPConnection,
        "callback_class" => "Gitorious::Authentication::LDAPAuthenticationTest::CallbackMock"
      })
      CallbackMock.reset
      Gitorious::LDAPTestHelper::StaticLDAPConnection.username = "moe"
    end

    it "does not call post_authenticate when login fails" do
      assert !@ldap.authenticate(valid_client_credentials("moe", "ohno"))
      assert !CallbackMock.called?
    end

    it "calls post_authenticate after successful login" do
      moe = User.new
      User.stubs(:find_by_login).with("moe").returns(moe)
      assert_equal moe, @ldap.authenticate(valid_client_credentials("moe","secret"))
      assert CallbackMock.called?
    end
  end

  describe "Authenticated binding" do
    it "uses authenticated bind when a bind user has been specified" do
      ldap = Gitorious::Authentication::LDAPAuthentication.new({
        "server" => "localhost",
        "base_dn" => "",
        "bind_user" => {"username" => "cn=guest"}
      })
      assert ldap.use_authenticated_bind?
    end
  end

  describe "Auto-registration" do
    before do
      @ldap = Gitorious::Authentication::LDAPAuthentication.new({
        "server" => "localhost",
        "base_dn" => "DC=gitorious,DC=org",
        "connection_type" => Gitorious::LDAPTestHelper::StaticLDAPConnection})
      Gitorious::LDAPTestHelper::StaticLDAPConnection.username = "moe.szyslak"
    end

    after do
      Gitorious::LDAPTestHelper::StaticLDAPConnection.login_attribute = "CN"
    end

    it "builds a synthetic email if LDAP entry has no email" do
      Gitorious::LDAPTestHelper::StaticLDAPConnection.return_empty_email_address! do
        user = @ldap.authenticate(valid_client_credentials("moe.szyslak", "secret"))
        assert_equal("moe.szyslak.example@#{Gitorious.host}", user.email)
      end
    end

    it "transforms user's login to not contain dots" do
      Gitorious::LDAPTestHelper::StaticLDAPConnection.username = "mr.moe.szyslak"
      user = @ldap.authenticate(valid_client_credentials("mr.moe.szyslak", "secret"))

      assert_equal "mr-moe-szyslak", user.login
    end

    it "searches using uid instead of cn" do
      @ldap = Gitorious::Authentication::LDAPAuthentication.new({
        "server" => "localhost",
        "base_dn" => "DC=gitorious,DC=org",
        "login_attribute" => "uid",
        "connection_type" => Gitorious::LDAPTestHelper::StaticLDAPConnection
      })
      Gitorious::LDAPTestHelper::StaticLDAPConnection.username = "mr.moe.szyslak"
      Gitorious::LDAPTestHelper::StaticLDAPConnection.login_attribute = "uid"
      user = @ldap.authenticate(valid_client_credentials("mr.moe.szyslak", "secret"))

      assert_equal "mr-moe-szyslak", user.login
    end
  end
end
