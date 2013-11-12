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

class SiteWikiPagesControllerTest < ActionController::TestCase
  should_render_in_site_specific_context

  def setup
    setup_ssl_from_config
  end

  context "show" do
    should "redirects to edit if the page is new, and user is logged in" do
      logout
      page_stub = stub("page stub", :new? => true, :title => "Home", :binary? => false)
      Site.any_instance.stubs(:wiki).returns(mock("git"))
      Page.stubs(:find).returns(page_stub)

      get :show, :id => "Home"
      assert_response :success
      assert_match /"Home" does not exist yet/, response.body
    end
  end

  context "Git cloning instructions" do
    should "render cloning instructions" do
      get :git_access
      assert_response :success
    end
  end

  context "internal git access urls" do
    should "respond to wiki/<sitename>/writable_by" do
      site = Site.create(:title => "Test");
      get :writable_by, :site_id => site.id
      assert_response :success
    end

    should "respond to wiki/<sitename>/config" do
      site = Site.create(:title => "Test");
      get :repository_config, :site_id => site.id
      assert_response :success
    end
  end
end
