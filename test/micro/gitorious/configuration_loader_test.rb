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
require "gitorious/configuration_loader"
require "app/models/project_license"

class ConfigurationLoader < MiniTest::Spec
  describe "configuring project licenses" do
    before do
      @loader = Gitorious::ConfigurationLoader.new
      @config = Gitorious::Configurable.new
    end

    describe "with no license configuration" do
      it "returns default licenses" do
        @loader.configure_available_singletons(@config)

        gpl = "GNU General Public License version 3 (GPLv3)"
        assert ProjectLicense.all.collect(&:to_s).include?(gpl)
      end
    end

    describe "with an array of licenses configured" do
      before do
        @config.append("licenses" => %w[MIT BSD GPL])
        @loader.configure_available_singletons(@config)
      end

      it "return configured licenses" do
        licenses = ProjectLicense.all

        assert_equal 3, licenses.length
        assert_equal "BSD", licenses[1].name
      end
    end

    describe "with an array of hashes of licenses configured" do
      before do
        @config.append("licenses" => [{ "MIT" => "No strings attached, no guarantees" },
                                      { "BSD" => "Keep the copyright" }])
        @loader.configure_available_singletons(@config)
      end

      it "return configured licenses" do
        licenses = ProjectLicense.all

        assert_equal 2, licenses.length
        assert_equal "BSD", licenses[1].name
        assert_equal "Keep the copyright", licenses[1].description
      end
    end

    describe "with a single license string configured" do
      before do
        @config.append("licenses" => "MIT")
        @loader.configure_available_singletons(@config)
      end

      it "return configured license in an array" do
        licenses = ProjectLicense.all
        assert_equal ["MIT"], licenses.collect(&:name)
      end
    end
  end
end
