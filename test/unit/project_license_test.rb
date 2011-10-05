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

require File.dirname(__FILE__) + '/../test_helper'

class ProjectLicenseTest < ActiveSupport::TestCase
  def setup
    ProjectLicense.instance_eval { @licenses = nil }
  end

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

  context "with no license configuration" do
    setup do
      GitoriousConfig.delete("licenses")
    end

    should "return default licenses" do
      gpl = "GNU General Public License version 3 (GPLv3)"
      assert ProjectLicense.all.collect(&:to_s).include?(gpl)
    end
  end

  context "with an array of licenses configured" do
    setup do
      GitoriousConfig["licenses"] = %w[MIT BSD GPL]
    end

    should "return configured licenses" do
      licenses = ProjectLicense.all

      assert_equal 3, licenses.length
      assert_equal "BSD", licenses[1].name
    end

    should "memoize licenses" do
      licenses = ProjectLicense.all
      GitoriousConfig["licenses"] = %w[MPL GPL2]

      assert_equal 3, licenses.length
      assert_equal "BSD", licenses[1].name
    end
  end

  context "with an array of hashes of licenses configured" do
    setup do
      GitoriousConfig["licenses"] = [{ "MIT" => "No strings attached, no guarantees" },
                                     { "BSD" => "Keep the copyright" }]
    end

    should "return configured licenses" do
      licenses = ProjectLicense.all

      assert_equal 2, licenses.length
      assert_equal "BSD", licenses[1].name
      assert_equal "Keep the copyright", licenses[1].description
    end

    should "memoize licenses" do
      licenses = ProjectLicense.all
      GitoriousConfig["licenses"] = %w[MPL GPL2 LGPL]

      assert_equal 2, licenses.length
      assert_equal "BSD", licenses[1].name
    end
  end

  context "with a single license string configured" do
    setup do
      GitoriousConfig["licenses"] = "MIT"
    end

    should "return configured license in an array" do
      licenses = ProjectLicense.all
      assert_equal ["MIT"], licenses.collect(&:name)
    end
  end
end
