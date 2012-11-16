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

class ProjectLicenseTest < ActiveSupport::TestCase
  context "licenses" do
    should "have name attribute" do
      license = ProjectLicense.all.first
      assert_equal "Academic Free License v3.0", license.name
    end

    should "have description attribute" do
      license = ProjectLicense.all.first
      assert_nil license.description
    end

    should "use name when converting to a string" do
      license = ProjectLicense.all.first
      assert_equal license.name, license.to_s
    end

    should "use name when inspecting" do
      license = ProjectLicense.all.first
      assert_equal license.name, license.inspect
    end
  end
end
