# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class ThemingTest < ActionDispatch::IntegrationTest
  should "render default CSS and JS in UI3" do
    get "/johans-project/johansprojectrepos/activities"

    assert_match "gitorious3.min.css", response.body
    assert_match "gitorious3.min.js", response.body
  end

  should "render theme CSS and JS in UI3" do
    Gitorious::Configuration.override({
        "theme_css" => "/theme.css",
        "theme_js" => "/theme.js"
      }) do
      get "/johans-project/johansprojectrepos/activities"

      assert_match "/theme.css", response.body
      assert_match "/theme.js", response.body
    end
  end

  should "render site-specific theme in UI3" do
    Site.any_instance.stubs(:subdomain).returns("mysite")
    Gitorious::Configuration.override({
        "theme_css" => "/default-theme.css",
        "theme_js" => "/default-theme.js",
        "sites" => {
          "mysite" => {
            "theme_css" => "/site-theme.css",
            "theme_js" => "/site-theme.js"
          }
        }
      }) do
      get "http://mysite.gitorious.local/johans-project/johansprojectrepos/activities"

      refute_match "default-theme", response.body
      assert_match "/site-theme.css", response.body
      assert_match "/site-theme.js", response.body
    end
  end
end
