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
require "gitorious/authentication/credentials"
require "gitorious/authentication/kerberos_authentication"

class Gitorious::Authentication::KerberosAuthenticationTest < MiniTest::Shoulda
  include Gitorious::KerberosTestHelper

  context "Configuration" do
    setup do
      @kerberos = Gitorious::Authentication::KerberosAuthentication.new({
        "realm" => "EXAMPLE.COM",
      })
    end

    should "require a realm" do
      assert_raises Gitorious::Authentication::ConfigurationError do
        kerberos = Gitorious::Authentication::KerberosAuthentication.new({})
      end
    end

    should "use a default email domain" do
      assert_equal "example.com", @kerberos.email_domain
    end
  end

  context "Authentication" do
    setup do
      @kerberos = Gitorious::Authentication::KerberosAuthentication.new({
        "realm" => "EXAMPLE.COM",
      })
    end

    should "not accept invalid credentials" do
      # Pass in an empty hash, to simulate the missing environment variables.
      assert !@kerberos.valid_kerberos_login({})
    end

    should "accept valid credentials" do
      env = Hash['HTTP_AUTHORIZATION' => 'Negotiate ABCDEF123456']
      assert @kerberos.valid_kerberos_login(env)
    end

    should "return the actual user" do
      moe = User.new(:login => "moe")
      User.stubs(:find_by_login).with("moe").returns(moe)
      assert_equal(moe, @kerberos.authenticate(valid_client_credentials("moe@EXAMPLE.COM")))
    end
  end

  context "Auto-registration" do
    setup do
      @kerberos = Gitorious::Authentication::KerberosAuthentication.new({
        "realm" => "EXAMPLE.COM",
      })
    end

    should "transform user's login to not contain dots" do
      user = @kerberos.authenticate(valid_client_credentials("mr.moe.szyslak@EXAMPLE.COM"))

      assert_equal "mr-moe-szyslak", user.login
    end
  end
end
