require File.dirname(__FILE__) + '/../spec_helper'
require 'tmpdir'

describe GitBackend do
  before(:each) do
    @repository = Repository.new({
      :name => "foo",
      :project => projects(:johans),
      :user => users(:johan)
    })
    
    FileUtils.mkdir_p(@repository.full_repository_path, :mode => 0755)
  end
  
  def push_something
    path = File.join(Dir.tmpdir, "gitorious.test")
    FileUtils.mkpath(path)
    
    Dir.chdir(path) do
      File.open("something", "w") do |file|
        file << "dummy #{rand}\n"
      end
      
      git = Grit::Git.new(File.join(path, ".git"))
      git.init({}, "--shared")
      git.add({}, "something")
      git.commit({:m => true}, "message")
      git.push({:all => true}, @repository.full_repository_path)
    end
  end
  
  
  it "creates a bare git repository" do
    path = @repository.full_repository_path 
    FileUtils.should_receive(:mkdir_p).with(path, :mode => 0750).and_return(true)
    FileUtils.should_receive(:touch).with(File.join(path, "git-daemon-export-ok"))
    GitBackend.should_receive(:execute_command).with(
      %Q{chmod +x #{File.join(path, "hooks/post-update")}}
    ).and_return(true)
    GitBackend.should_receive(:execute_command).with(
      %Q{GIT_DIR="#{path}" git-update-server-info}
    ).and_return(true)
  
    GitBackend.create(path)
  end
  
  it "clones an existing repos into a bare one" do
    source_path = @repository.full_repository_path 
    target_path = repositories(:johans).full_repository_path 
    FileUtils.should_receive(:touch).with(File.join(target_path, "git-daemon-export-ok"))
    GitBackend.should_receive(:execute_command).with(
      %Q{chmod +x #{File.join(target_path, "hooks/post-update")}}
    ).and_return(true)
    GitBackend.should_receive(:execute_command).with(
      %Q{GIT_DIR="#{target_path}" git-update-server-info}
    ).and_return(true)
      
    push_something
    GitBackend.clone(target_path, source_path)
#     File.exist?(File.join(target_path, "hooks")).should == false
  end
  
  it "deletes a git repository" do
    base_path = "/base/path"
    repos_path = base_path + "/repo"
    GitoriousConfig.should_receive(:[]).with("repository_base_path").and_return(base_path)
    FileUtils.should_receive(:rm_rf).with(repos_path).and_return(true)
    GitBackend.delete!(repos_path)
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
