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


require File.dirname(__FILE__) + '/../../test_helper'

class RepositoriesHelperTest < ActionView::TestCase
  
  class OurTestController < ApplicationController
    attr_accessor :request, :response, :params

    def initialize
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new
      
      @params = {}
      send(:initialize_current_url)
    end
  end
  
  def repo_owner_path(*args)
    @controller.send(:repo_owner_path, *args)
  end
  
  def setup
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @controller = OurTestController.new
  end
  
  def generic_sha(letter = "a")
    letter * 40
  end
  
  # should "has a commit_path shortcut" do
  #   assert_equal project_repository_commit_path(@project, @repository, "master"), commit_path
  #   assert_equal project_repository_commit_path(@project, @repository, "foo"), commit_path("foo")
  # end
  
  # Commented out because rspec seems to fail at understanding helper_method, boo!
  # it "has a log_path shortcut" do
  #   assert_equal project_repository_commits_path(@project, @repository, ["master"]), #   helper.log_path("master")
  # end
  #
  # it "has a log_path shortcut that takes args" do
  #   assert_equal project_repository_commits_path(@project, , #   helper.log_path("master", :page => 2)
  #     @repository, ["master"], {:page => 2})
  # end
  # 
  # it "has a tree_path shortcut" do
  #  assert_equal project_repository_tree_path(@project, @repository, "master"), #   tree_path
  # end
  # 
  # it "has a tree_path shortcut that takes an sha1" do
  #   assert_equal project_repository_tree_path(@project, @repository, "foo"), #   tree_path("foo")
  # end
  #   
  # it "has a tree_path shortcut that takes an sha1 and a path glob" do
  #   assert_equal project_repository_tree_path(@project, , #   tree_path("foo", %w[a b c])
  #     @repository, "foo", ["a", "b", "c"])
  # end
  # 
  # it "has a tree_path shortcut can takes a path string and turns it into a glob" do
  #   assert_equal project_repository_tree_path(@project, , #   tree_path("foo", "a/b/c")
  #     @repository, "foo", ["a", "b", "c"])
  # end
  #
  # it "has a blob_path shortcut" do
  #    assert_equal project_repository_blob_path(@project, , #   blob_path(generic_sha, ["a","b"])
  #     @repository, generic_sha, ["a","b"])
  # end
  # 
  # it "has a raw_blob_path shortcut" do
  #    assert_equal project_repository_raw_blob_path(, #   raw_blob_path(generic_sha, ["a","b"])
  #     @project, @repository, generic_sha, ["a","b"])
  # end
  
  should "knows if a branch is namespaced" do
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
