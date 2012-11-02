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

  context "index action" do
    should "render" do
      git_stub = stub("git", {
        :tree => stub(:contents => [mock("node", :name => "Foo"), mock("node", :name => "Bar")])
      })
      Site.any_instance.stubs(:wiki).returns(git_stub)
      get :index
      assert_response :success
    end

    should "render the history atom feed" do
      grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
      Site.any_instance.stubs(:wiki).returns(grit)

      get :index, :format => "atom"

      assert_response :success
      assert_equal grit.commits("master", 30), assigns(:commits)
      assert_equal "max-age=1800, private", @response.headers["Cache-Control"]
      assert_match @response.body, /<author>/
    end
  end

  context "show" do
    should "redirects to edit if the page is new, and user is logged in" do
      logout
      page_stub = mock("page stub")
      page_stub.expects(:new?).returns(true)
      page_stub.expects(:title).at_least_once.returns("Home")
      Site.any_instance.expects(:wiki).returns(mock("git"))
      Page.expects(:find).returns(page_stub)

      get :show, :id => "Home"
      assert_response :success
      assert_select ".help-box p", /page "Home" does not exist yet/
    end
  end

  context "Preview" do
    setup do
      page_stub = mock("page stub")
      page_stub.expects(:content=)
      page_stub.expects(:content).returns("Messing around with wiki markup")
      page_stub.expects(:save).never
      Site.any_instance.expects(:wiki).returns(mock("git"))
      Page.expects(:find).returns(page_stub)
    end

    should "render the preview for an existing page" do
      login_as :johan
      put :preview, :id => "Sandbox", :format => "js", :page => {:content => "Foo"}
      assert_response :success
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
