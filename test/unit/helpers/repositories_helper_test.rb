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

class RepositoriesHelperTest < ActionView::TestCase

  class OurTestController < ApplicationController
    attr_accessor :request, :response, :params

    def initialize
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new

      @params = {}
    end
  end

  def setup
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @controller = OurTestController.new
  end

  def generic_sha(letter = "a")
    letter * 40
  end

  should "know if a branch is namespaced" do
    assert !namespaced_branch?("foo")
    assert namespaced_branch?("foo/bar")
    assert namespaced_branch?("foo/bar/baz")
  end

  context "sorted git heads" do
    should "sort by name, with the HEAD first" do
      heads = [
        stub("git head", :name => "c", :head? => true),
        stub("git head", :name => "a", :head? => false),
        stub("git head", :name => "b", :head? => false),
      ]
      assert_equal %w[c a b], sorted_git_heads(heads).map(&:name)
    end

    should "not include a nil item when there is no head" do
      heads = [
        stub("git head", :name => "c", :head? => false),
        stub("git head", :name => "a", :head? => false),
        stub("git head", :name => "b", :head? => false),
      ]
      assert_equal %w[a b c], sorted_git_heads(heads).map(&:name)
    end
  end
end
