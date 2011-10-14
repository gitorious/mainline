# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class PagesControllerTest < ActionController::TestCase

  should_render_in_site_specific_context
  should_enforce_ssl_for(:get, :edit)
  should_enforce_ssl_for(:get, :git_access)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :show)
  should_enforce_ssl_for(:put, :preview)

  def setup
    @project = projects(:johans)
    @repo = @project.wiki_repository
  end

  context "repository readyness" do
    should " be ready on #index" do
      Repository.any_instance.stubs(:ready?).returns(false)
      get :index, :project_id => @project.to_param
      assert_redirected_to(project_path(@project))
      assert_match(/is being created/, flash[:notice])
    end

    should " be ready on #show" do
      Repository.any_instance.stubs(:ready?).returns(false)
      get :show, :project_id => @project.to_param, :id => "Home"
      assert_redirected_to(project_path(@project))
      assert_match(/is being created/, flash[:notice])
    end
  end

  context "index" do
    should "renders an index" do
      git_stub = stub("git", {
        :tree => stub(:contents => [mock("node", :name => "Foo"), mock("node", :name => "Bar")])
      })
      Repository.any_instance.stubs(:git).returns(git_stub)
      get :index, :project_id => @project.to_param
      assert_response :success
    end

    should "redirects to the project if wiki is disabled for this projcet" do
      @project.update_attribute(:wiki_enabled, false)
      get :index, :project_id => @project.to_param
      assert_redirected_to(project_path(@project))
    end

    should "render the history atom feed" do
      grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
      Repository.any_instance.stubs(:git).returns(grit)
      get :index, :project_id => @project.to_param, :format => "atom"
      assert_response :success
      assert_equal grit.commits("master", 30), assigns(:commits)
      assert_template "index.atom.builder"
      assert_equal "max-age=1800, private", @response.headers['Cache-Control']
    end
  end

  context "show" do
    should "redirects to edit if the page is new, and user is logged in" do
      login_as nil
      page_stub = mock("page stub")
      page_stub.expects(:new?).returns(true)
      page_stub.expects(:title).at_least_once.returns("Home")
      Repository.any_instance.expects(:git).returns(mock("git"))
      Page.expects(:find).returns(page_stub)

      get :show, :project_id => @project.to_param, :id => "Home"
      assert_response :success
      assert_select ".help-box p", /page "Home" does not exist yet/
    end

    should "redirects to the project if wiki is disabled for this projcet" do
      @project.update_attribute(:wiki_enabled, false)
      get :show, :project_id => @project.to_param, :id => "Foo"
      assert_redirected_to(project_path(@project))
    end
  end

  context 'Preview' do
    setup do
      page_stub = mock("page stub")
      page_stub.expects(:content=)
      page_stub.expects(:content).returns("Messing around with wiki markup")
      page_stub.expects(:save).never
      Repository.any_instance.expects(:git).returns(mock("git"))
      Page.expects(:find).returns(page_stub)
    end

    should 'render the preview for an existing page' do
      login_as :johan
      put :preview, :project_id => @project.to_param, :id => "Sandbox", :format => 'js', :page => {:content => 'Foo'}
      assert_response :success
    end
  end

  context "write permissions restricted to project members" do
    setup do
      @repo.update_attribute(:wiki_permissions, Repository::WIKI_WRITABLE_PROJECT_MEMBERS)
    end

    should "redirect back for non-projectmembers" do
      assert !@project.member?(users(:mike))
      login_as :mike
      get :edit, :project_id => @project.to_param, :id => "NotHere"
      assert_response :redirect
      assert_match(/restricted wiki editing to project members/, flash[:error])
      assert_redirected_to project_pages_path(@project)
    end
  end

  context "Git cloning instructions" do
    should "render cloning instructions" do
      get :git_access, :project_id => @project.to_param
      assert_response :success
    end
  end
end
