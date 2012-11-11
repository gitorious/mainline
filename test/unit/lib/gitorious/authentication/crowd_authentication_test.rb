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
require "net/http"
require "rexml/document"
require "authentication_test_helper"

class Gitorious::Authentication::ConfigurationTest < ActiveSupport::TestCase
  include Gitorious::CrowdTestHelper

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
  end
end
