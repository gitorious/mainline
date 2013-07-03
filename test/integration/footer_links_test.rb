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

class FooterLinksTest < ActionDispatch::IntegrationTest
  should "render default footer links in UI3" do
    get "/johans-project/johansprojectrepos/activities"

    assert_response :success
    assert_match "About Gitorious", response.body
    assert_match "http://groups.google.com/group/gitorious", response.body
  end

  should "render additional footer links in UI3" do
    Gitorious::Configuration.override({ "additional_footer_links" => [["A", "/gogogo"]] }) do
      get "/johans-project/johansprojectrepos/activities"

      assert_match "/gogogo", response.body
    end
  end

  should "render configured footer links in UI3" do
    Gitorious::Configuration.override({
        "footer_links" => [["#1", "/gogogo"], ["#2", "/here"]]
      }) do
      get "/johans-project/johansprojectrepos/activities"

      assert_match "#1", response.body
      assert_match "/gogogo", response.body
      assert_match "#2", response.body
      assert_match "/here", response.body
      refute_match "About Gitorious", response.body
    end
  end

  should "render site-specific footer links in UI3" do
    Site.any_instance.stubs(:subdomain).returns("mysite")
    Gitorious::Configuration.override({
        "footer_links" => [["#1", "/gogogo"], ["#2", "/here"]],
        "sites" => {
          "mysite" => {
            "footer_links" => [["#3", "/somewhere"]]
          }
        }
      }) do
      get "http://mysite.gitorious.local/johans-project/johansprojectrepos/activities"

      refute_match "#1", response.body
      assert_match "#3", response.body
      assert_match "/somewhere", response.body
    end
  end
end
