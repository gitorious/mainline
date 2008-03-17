require File.dirname(__FILE__) + '/../spec_helper'

describe RepositoriesHelper do
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
  
  it "has a archive_tree_path shortcut" do
    archive_tree_path.should == project_repository_archive_tree_path(@project, @repository, "master")
    archive_tree_path("foo").should == project_repository_archive_tree_path(@project, @repository, "foo")
  end
  
  it "has a blob_path shortcut" do
    blob_path(generic_sha, ["a","b"]).should == project_repository_blob_path(@project, 
      @repository, generic_sha, ["a","b"])
  end
  
  it "has a raw_blob_path shortcut" do
    raw_blob_path(generic_sha, ["a","b"]).should == project_repository_raw_blob_path(
      @project, @repository, generic_sha, ["a","b"])
  end
end
