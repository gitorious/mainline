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
class Gitorious::Authentication::KerberosAuthenticationTest < ActiveSupport::TestCase

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
      assert_equal(users(:moe), @kerberos.authenticate(valid_client_credentials("moe@EXAMPLE.COM")))
    end
  end

  context "Auto-registration" do
    setup do
      @kerberos = Gitorious::Authentication::KerberosAuthentication.new({
          "realm" => "EXAMPLE.COM",
        })
    end

    should "create a new user with attributes mapped from Kerberos" do
      user = @kerberos.authenticate(valid_client_credentials("moe.szyslak@EXAMPLE.COM"))
      assert_equal "moe.szyslak@example.com", user.email
      assert_equal "moe-szyslak", user.login

      assert user.valid?
    end

    should "transform user's login to not contain dots" do
      user = @kerberos.authenticate(valid_client_credentials("mr.moe.szyslak@EXAMPLE.COM"))

      assert_equal "mr-moe-szyslak", user.login
    end
  end
end
