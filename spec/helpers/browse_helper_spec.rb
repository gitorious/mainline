require File.dirname(__FILE__) + '/../spec_helper'

describe BrowseHelper do
  
  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  it "has a browse_path shortcut" do
    browse_path.should == project_repository_browse_path(@project, @repository)
  end
  
  it "has a log_path shortcut" do
    log_path.should == project_repository_log_path(@project, @repository)
  end
  
  it "has a log_path shortcut that takes args" do
    log_path(:page => 2).should == project_repository_log_path(@project, 
      @repository, {:page => 2})
  end

  it "has a tree_path shortcut" do
    tree_path.should == project_repository_tree_path(@project, @repository)
  end
  
  it "has a tree_path shortcut that takes an sha1" do
    tree_path("abc123").should == project_repository_tree_path(@project, 
      @repository, "abc123")
  end
  
  it "has a tree_path shortcut that takes an sha1 and a path glob" do
    tree_path("abc123", ["a", "b"]).should == project_repository_tree_path(@project, 
      @repository, "abc123", ["a", "b"])
  end
  
  it "has a commit_path shortcut" do
    commit_path("abc123").should == project_repository_commit_path(@project, 
      @repository, "abc123")
  end

  it "has a blob_path shortcut" do
    blob_path("sha", ["a","b"]).should == project_repository_blob_path(@project, 
      @repository, "sha", ["a","b"])
  end
  
  it "has a raw_blob_path shortcut" do
    raw_blob_path("sha", ["a","b"]).should == project_repository_raw_blob_path(
      @project, @repository, "sha", ["a","b"])
  end

  it "has a diff_path shortcut" do
    diff_path("old", "new").should == project_repository_diff_path(@project, 
      @repository, "old", "new")    
  end
  
  it "has a current_path based on the *path glob" do
    params[:path] = ["one", "two"]
    current_path.should == ["one", "two"]
  end
  
  it "builds a tree from current_path" do
    params[:path] = ["one", "two"]
    build_tree_path("three").should == ["one", "two", "three"]
  end
  
  it "builds breadcrumbs of the current_path" do
    stub!(:current_path).and_return(["one", "two", "tree"])
    breadcrumb_path.should include(%Q{<ul class="path_breadcrumbs">})
    breadcrumb_path.should include("<li> / ")
  end
  
end
