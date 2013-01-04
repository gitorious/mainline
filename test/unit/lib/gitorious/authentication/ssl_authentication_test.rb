# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class Gitorious::Authentication::SSLAuthenticationTest < ActiveSupport::TestCase
  include Gitorious::SSLTestHelper

  context "Auto-registration" do
    setup do
      @ssl = Gitorious::Authentication::SSLAuthentication.new({
          "login_field" => "Email",
          "login_strip_domain" => true,
          "login_replace_char" => "",
        })
      @cn = 'John Doe'
      @email = 'j.doe@example.com'
    end

    should "create a new user with information from the SSL client certificate" do
      user = @ssl.authenticate(valid_client_credentials(@cn, @email))

      assert_equal "jdoe", user.login
      assert_equal @email, user.email
      assert_equal @cn, user.fullname

      assert user.valid?
    end
  end
end
