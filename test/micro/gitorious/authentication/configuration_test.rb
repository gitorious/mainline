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
require "gitorious/authentication/configuration"
require "gitorious/authentication/database_authentication"
require "gitorious/authentication/ldap_authentication"

class Gitorious::Authentication::ConfigurationTest < MiniTest::Spec
  describe "Default configuration" do
    before do
      Gitorious::Authentication::Configuration.authentication_methods.clear
    end

    it "uses database authentication as default" do
      assert_equal 0, Gitorious::Authentication::Configuration.authentication_methods.size
      Gitorious::Authentication::Configuration.configure({})
      assert_equal 1, Gitorious::Authentication::Configuration.authentication_methods.size
    end

    it "only excludes database authentication when instructed to do so" do
      Gitorious::Authentication::Configuration.configure({"disable_default" => "true"})
      assert_equal 0, Gitorious::Authentication::Configuration.authentication_methods.size
    end

    it "does not allow several auth methods of same type" do
      2.times {Gitorious::Authentication::Configuration.use_default_configuration}
      assert_equal 1, Gitorious::Authentication::Configuration.authentication_methods.size
    end
  end

  describe "LDAP authentication" do
    before do
      Gitorious::Authentication::Configuration.authentication_methods.clear
      options = {"methods" => [{ "adapter" => "Gitorious::Authentication::LDAPAuthentication",
                                 "server" => "directory.example",
                                 "base_dn" => "DC=gitorious,DC=org",
                                 "port" => "998",
                                 "encryption" => "simple_tls",
                                 "attribute_mapping" => {"displayname"=> "fullname"}
                               }]}
      Gitorious::Authentication::Configuration.configure(options)
      @ldap = Gitorious::Authentication::Configuration.authentication_methods.last
    end

    it "configures LDAP authentication" do
      assert_equal "directory.example", @ldap.server
    end
  end

  describe "OpenID authentication" do
    before do
      Gitorious::Authentication::Configuration.reset!
    end

    it "is enabled by default" do
      assert Gitorious::Authentication::Configuration.openid_enabled?, "Openid should be enabled. Current methods are #{Gitorious::Authentication::Configuration.authentication_methods.inspect}"
    end

    it "disables OpenID" do
      Gitorious::Authentication::Configuration.configure({"enable_openid" => false})
      refute Gitorious::Authentication::Configuration.openid_enabled?
    end
  end
end
