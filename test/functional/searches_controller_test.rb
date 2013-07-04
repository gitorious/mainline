# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

require "test_helper"

class SearchesControllerTest < ActionController::TestCase
  should_render_in_global_context

  context "#show" do
    should "search for the given query" do
      search_result = [projects(:johans)]

      ThinkingSphinx.expects(:search).with("foo",{
        :page => 1, :per_page => 30,
        :classes => [Project, Repository, MergeRequest],
       :match_mode => :extended
      }).returns(search_result)

      search_result.expects(:total_entries).returns(1)
      search_result.expects(:query_time).returns(42)

      get :show, :q => "foo"
      assert_equal search_result, assigns(:all_results)
      assert_equal [projects(:johans)], assigns(:results)
    end

    should "not search if there is no :q param" do
      ThinkingSphinx.expects(:search).never
      get :show, :q => ""
      assert_nil assigns(:results)
    end
  end

  context "With private repositories" do
    setup do
      @project = Project.first
      search_results = Project.all.concat(Repository.all)
      enable_private_repositories
      ThinkingSphinx.stubs(:search).returns(search_results)

      search_results.stubs(:total_pages).returns(1)
      search_results.stubs(:total_entries).returns(search_results.length)
      search_results.stubs(:query_time).returns(42)
    end

    should "filter out unauthorized results" do
      get :show, :q => "gitorious"
      assert_response :success
      assert(assigns(:results).none? do |r|
        (r.respond_to?(:project) ? r.project : r) == @project
      end)
      assert_match /Found 4 results/, @response.body
    end

    should "not filter out authorized results" do
      login_as :johan
      get :show, :q => "gitorious"

      assert(assigns(:results).any? do |r|
        (r.respond_to?(:project) ? r.project : r) == @project
      end)
      assert_match /Found 8 results/, @response.body
    end
   end
end
