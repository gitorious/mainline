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
require "fast_test_helper"
require "gitorious/authorization/configuration"

class Gitorious::Authorization::ConfigurationTest < MiniTest::Spec
  describe "Default configuration" do
    before do
      Gitorious::Authorization::Configuration.strategies.clear
    end

    it "uses commitership authorization as default" do
      assert_equal 0, Gitorious::Authorization::Configuration.strategies.size
      Gitorious::Authorization::Configuration.configure({})
      assert_equal 1, Gitorious::Authorization::Configuration.strategies.size
    end

    it "only excludes committerships when instructed to do so" do
      Gitorious::Authorization::Configuration.configure({ "disable_default" => "true" })
      assert_equal 0, Gitorious::Authorization::Configuration.strategies.size
    end

    it "does not allow several auth methods of same type" do
      2.times { Gitorious::Authorization::Configuration.use_default_configuration }
      assert_equal 1, Gitorious::Authorization::Configuration.strategies.size
    end
  end
end
