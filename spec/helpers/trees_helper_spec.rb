require File.dirname(__FILE__) + '/../spec_helper'

describe TreesHelper do
  
  it "includes the RepostoriesHelper" do
    included_modules = (class << helper; self; end).send(:included_modules)
    included_modules.should include(RepositoriesHelper)
  end
  
  describe "commit_for_tree_path" do
    it "fetches the most recent commit from the path" do
      repo = mock("repository")
      git = mock("Git")
      repo.should_receive(:git).and_return(git)
      git.should_receive(:log).and_return([mock("commit")])
      commit_for_tree_path(repo, "foo/bar/baz.rb")
    end
  end
  
  it "has a current_path based on the *path glob" do
    params[:path] = ["one", "two"]
    current_path.should == ["one", "two"]
  end
  
  it "builds a tree from current_path" do
    params[:path] = ["one", "two"]
    build_tree_path("three").should == ["one", "two", "three"]
  end
  
end
