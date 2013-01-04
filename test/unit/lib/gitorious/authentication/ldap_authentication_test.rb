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
require "test_helper"
require "authentication_test_helper"

class Gitorious::Authentication::LDAPAuthenticationTest < ActiveSupport::TestCase
  include Gitorious::LDAPTestHelper

  context "Auto-registration" do
    setup do
      @ldap = Gitorious::Authentication::LDAPAuthentication.new({
          "server" => "localhost",
          "base_dn" => "DC=gitorious,DC=org",
          "connection_type" => Gitorious::LDAPTestHelper::StaticLDAPConnection
      })
      Gitorious::LDAPTestHelper::StaticLDAPConnection.username = "moe.szyslak"
    end

    teardown do
      Gitorious::LDAPTestHelper::StaticLDAPConnection.login_attribute = "CN"
    end

    should "create a new user with attributes mapped from LDAP" do
      user = @ldap.authenticate(valid_client_credentials("moe.szyslak", "secret"))
      assert_equal "moe@gitorious.org", user.email
      assert_equal "Moe Szyslak", user.fullname
      assert_equal "moe-szyslak", user.login

      assert user.valid?
    end
  end
end
