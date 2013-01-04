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

class Admin::DiagnosticsControllerTest < ActionController::TestCase
  context "summary" do
    should "disallow 0.0.0.0 if explicitly left out" do
      Gitorious::Configuration.override("remote_ops_ips" => "192.168.122.1") do |conf|
        get :summary
        assert_response 403
      end
    end

    should "allow 0.0.0.0 if explicitly included" do
      ips = ["0.0.0.0", "192.168.122.1"]
      Gitorious::Configuration.override("remote_ops_ips" => ips) do |conf|
        get :summary
        assert_response 200
      end
    end
  end
end
