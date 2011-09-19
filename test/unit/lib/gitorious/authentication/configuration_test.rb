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
class Gitorious::Authentication::ConfigurationTest < ActiveSupport::TestCase
  context "Default configuration" do
    setup do
      Gitorious::Authentication::Configuration.authentication_methods.clear
    end

    should "use database authentication as default" do
      assert_equal 0, Gitorious::Authentication::Configuration.authentication_methods.size
      Gitorious::Authentication::Configuration.configure({})
      assert_equal 1, Gitorious::Authentication::Configuration.authentication_methods.size
    end

    should "only exclude database authentication when instructed to do so" do
      Gitorious::Authentication::Configuration.configure({"disable_default" => "true"})
      assert_equal 0, Gitorious::Authentication::Configuration.authentication_methods.size      
    end

    should "not allow several auth methods of same type" do
      2.times {Gitorious::Authentication::Configuration.use_default_configuration}
      assert_equal 1, Gitorious::Authentication::Configuration.authentication_methods.size
    end
  end

  context "LDAP authentication" do
    setup do
      Gitorious::Authentication::Configuration.authentication_methods.clear
      options = {"methods" => [{
                                 "adapter" => "Gitorious::Authentication::LDAPAuthentication",
                                 "server" => "directory.example",
                                 "base_dn" => "DC=gitorious,DC=org",
                                 "port" => "998",
                                 "encryption" => "simple_tls",
                                 "attribute_mapping" => {"displayname"=> "fullname"}
                               }]}
      Gitorious::Authentication::Configuration.configure(options)
      @ldap = Gitorious::Authentication::Configuration.authentication_methods.last
    end
    
    should "configure LDAP authentication" do
      assert_equal "directory.example", @ldap.server
    end
  end
end
