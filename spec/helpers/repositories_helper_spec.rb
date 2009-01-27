#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
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

require File.dirname(__FILE__) + '/../spec_helper'

describe RepositoriesHelper do
  
  include RepositoriesHelper
  
  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def generic_sha(letter = "a")
    letter * 40
  end
  
  it "has a commit_path shortcut" do
    commit_path.should == project_repository_commit_path(@project, @repository, "master")
    commit_path("foo").should == project_repository_commit_path(@project, @repository, "foo")
  end
  
  it "has a log_path shortcut" do
    log_path("master").should == project_repository_log_path(@project, @repository, "master")
  end
  
  it "has a log_path shortcut that takes args" do
    log_path("master", :page => 2).should == project_repository_log_path(@project, 
      @repository, "master", {:page => 2})
  end

  it "has a tree_path shortcut" do
    tree_path.should == project_repository_tree_path(@project, @repository, "master")
  end
  
  it "has a tree_path shortcut that takes an sha1" do
    tree_path("foo").should == project_repository_tree_path(@project, @repository, "foo")
  end
  
  it "has a tree_path shortcut that takes an sha1 and a path glob" do
    tree_path("foo", %w[a b c]).should == project_repository_tree_path(@project, 
      @repository, "foo", ["a", "b", "c"])
  end
  
  it "has a tree_path shortcut can takes a path string and turns it into a glob" do
    tree_path("foo", "a/b/c").should == project_repository_tree_path(@project, 
      @repository, "foo", ["a", "b", "c"])
  end
  
  it "has a archive_tree_path shortcut" do
    archive_tree_path.should == project_repository_archive_tree_path(@project, @repository, "master", "tar.gz")
    archive_tree_path("foo").should == project_repository_archive_tree_path(@project, @repository, "foo", "tar.gz")
    archive_tree_path("foo", "zip").should == project_repository_archive_tree_path(@project, @repository, "foo", "zip")
  end
  
  it "has a blob_path shortcut" do
    blob_path(generic_sha, ["a","b"]).should == project_repository_blob_path(@project, 
      @repository, generic_sha, ["a","b"])
  end
  
  it "has a raw_blob_path shortcut" do
    raw_blob_path(generic_sha, ["a","b"]).should == project_repository_raw_blob_path(
      @project, @repository, generic_sha, ["a","b"])
  end
  
  it "knows if a branch is namespaced" do 
    helper.namespaced_branch?("foo").should == false
    helper.namespaced_branch?("foo/bar").should == true
    helper.namespaced_branch?("foo/bar/baz").should == true
  end
end
