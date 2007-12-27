require File.dirname(__FILE__) + '/../spec_helper'

describe GitBackend do
  before(:each) do
    @repository = Repository.new({
      :name => "foo",
      :project => projects(:johans),
      :user => users(:johan)
    })
  end
  
  it "creates a bare git repository" do
    path = @repository.full_repository_path 
    FileUtils.should_receive(:mkdir_p).with(path, :mode => 0750).and_return(true)
    Dir.should_receive(:chdir).with(path).and_yield(path)
    Git.should_receive(:init).with(path, :repository => path).and_return(true)
    FileUtils.should_receive(:touch).with(File.join(path, "git-daemon-export-ok"))
  
    GitBackend.create(path)
  end
  
  it "clones an existing repos into a bare one" do
    source_path = @repository.full_repository_path 
    target_path = repositories(:johans).full_repository_path 
    Git.should_receive(:clone).with(source_path, target_path, :bare => true).and_return(true)
    FileUtils.should_receive(:touch).with(File.join(target_path, "git-daemon-export-ok"))
  
    GitBackend.clone(target_path, source_path)
  end
  
  it "deletes a git repository" do
    path = @repository.full_repository_path 
    FileUtils.should_receive(:rm_rf).with(path).and_return(true)
    GitBackend.delete!(path)
  end
  
  it "knows if a repos has commits" do
    path = @repository.full_repository_path 
    dir_mock = mock("Dir mock")
    Dir.should_receive(:[]).with(File.join(path, "refs/heads/*")).and_return(dir_mock)
    dir_mock.should_receive(:size).and_return(0)
    GitBackend.repository_has_commits?(path).should == false
  end
  
  it "knows if a repos has commits, if there's more than 0 heads" do
    path = @repository.full_repository_path 
    dir_mock = mock("Dir mock")
    Dir.should_receive(:[]).with(File.join(path, "refs/heads/*")).and_return(dir_mock)
    dir_mock.should_receive(:size).and_return(1)
    GitBackend.repository_has_commits?(path).should == true
  end
  
end