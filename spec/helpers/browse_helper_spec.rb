require File.dirname(__FILE__) + '/../spec_helper'

describe BrowseHelper do
  
  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
  end
  
  def generic_sha(letter = "a")
    letter * 40
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
    tree_path(generic_sha).should == project_repository_tree_path(@project, 
      @repository, generic_sha)
  end
  
  it "has a tree_path shortcut that takes an sha1 and a path glob" do
    tree_path(generic_sha, ["a", "b"]).should == project_repository_tree_path(@project, 
      @repository, generic_sha, ["a", "b"])
  end
  
  it "has a commit_path shortcut" do
    commit_path(generic_sha).should == project_repository_commit_path(@project, 
      @repository, generic_sha)
  end

  it "has a blob_path shortcut" do
    blob_path(generic_sha, ["a","b"]).should == project_repository_blob_path(@project, 
      @repository, generic_sha, ["a","b"])
  end
  
  it "has a raw_blob_path shortcut" do
    raw_blob_path(generic_sha, ["a","b"]).should == project_repository_raw_blob_path(
      @project, @repository, generic_sha, ["a","b"])
  end

  it "has a diff_path shortcut" do
    diff_path(generic_sha("a"), generic_sha("b")).should == project_repository_diff_path(@project, 
      @repository, generic_sha("a"), generic_sha("b"))    
  end
  
  it "has a current_path based on the *path glob" do
    params[:path] = ["one", "two"]
    current_path.should == ["one", "two"]
  end
  
  it "builds a tree from current_path" do
    params[:path] = ["one", "two"]
    build_tree_path("three").should == ["one", "two", "three"]
  end
  
  describe "with_line_numbers" do
    it "renders something with line numbers" do
      numbered = with_line_numbers { "foo\nbar\nbaz" }
      numbered.should include(%Q{<td class="line-numbers"><a href="#line2" name="line2">2</a></td>})
      numbered.should include(%Q{<td class="code">bar</td>})
    end
  
    it "renders one line with line numbers" do
      numbered = with_line_numbers { "foo" }
      numbered.should include(%Q{<td class="line-numbers"><a href="#line1" name="line1">1</a></td>})
      numbered.should include(%Q{<td class="code">foo</td>})
    end
  
    it "doesn't blow up when with_line_numbers receives nil" do
      proc{
        with_line_numbers{ nil }.should == "<table id=\"codeblob\">\n</table>"
      }.should_not raise_error
    end
  end
  
  # it "builds breadcrumbs of the current_path" do
  #   stub!(:current_path).and_return(["one", "two", "tree"])
  #   breadcrumb_path.should include(%Q{<ul class="path_breadcrumbs">})
  #   breadcrumb_path.should include("<li> / ")
  # end
  
end
