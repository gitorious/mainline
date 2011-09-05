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

class SearchesControllerTest < ActionController::TestCase

  should_render_in_global_context
  should_enforce_ssl_for(:get, :show)

  context "#show" do
    should "search for the given query" do
      searcher = mock("ultrasphinx search")
      Ultrasphinx::Search.expects(:new).with({
        :query => "foo", :page => 1, :per_page => 30
      }).returns(searcher)
      searcher.expects(:run)
      searcher.expects(:results).returns([projects(:johans)])
      searcher.expects(:total_pages).returns(1)
      searcher.expects(:total_entries).returns(1)
      searcher.expects(:time).returns(42)

      get :show, :q => "foo"
      assert_equal searcher, assigns(:search)
      assert_equal [projects(:johans)], assigns(:results)
    end

    should "not search if there is no :q param" do
      Ultrasphinx::Search.expects(:new).never
      get :show, :q => ""
      assert_nil assigns(:search)
      assert_nil assigns(:results)
    end

    context "paginating search results" do
      setup do
        searcher = mock()
        searcher.stubs(:run)
        searcher.stubs(:results).returns([])
        searcher.stubs(:total_pages).returns(1)
        searcher.stubs(:total_entries).returns(1)
        searcher.stubs(:time).returns(42)
        Ultrasphinx::Search.stubs(:new).returns(searcher)
        @params = { :q => "foo" }
      end

      should_scope_pagination_to(:show, nil, "search results", :delete_all => false)
    end
  end
end
