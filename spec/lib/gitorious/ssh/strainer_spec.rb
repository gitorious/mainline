require File.dirname(__FILE__) + '/../../../spec_helper'

describe Gitorious::SSH::Strainer do
  
  it "raises if command includes a newline" do
    proc{ 
      Gitorious::SSH::Strainer.new("foo\nbar").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
  end
  
  it "raises if command has more than one argument" do
    proc{ 
      Gitorious::SSH::Strainer.new("git-upload-pack 'bar baz'").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
  end
  
  it "raises if command doesn't have an argument" do
    proc{ 
      Gitorious::SSH::Strainer.new("git-upload-pack").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
  end
  
  it "raises if it gets a bad command" do
    proc {
      Gitorious::SSH::Strainer.new("evil 'foo'").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
  end
  
  it "raises if it receives an unsafe argument" do
    proc {
      Gitorious::SSH::Strainer.new("git-upload-pack /evil/attack").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
  end
  
  it "raises if it receives an unsafe argument that almost looks kosher" do
    proc {
      Gitorious::SSH::Strainer.new("git-upload-pack '/evil/path'").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
    
    proc {
      Gitorious::SSH::Strainer.new("git-upload-pack /evil/\\\\\\//path").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
    
    proc {
      Gitorious::SSH::Strainer.new("git-upload-pack ../../evil/path").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
    
    proc {
      Gitorious::SSH::Strainer.new("git-upload-pack 'evil/path.git.bar'").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
  end
  
  it "raises if it receives an empty path" do
    proc {
      Gitorious::SSH::Strainer.new("git-upload-pack ''").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
    
    proc {
      Gitorious::SSH::Strainer.new("git-upload-pack ").parse!
    }.should raise_error(Gitorious::SSH::BadCommandError)
  end
  
  it "returns self when running #parse" do
    strainer = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'")
    strainer2 = strainer.parse!
    strainer2.should be_instance_of(Gitorious::SSH::Strainer)
    strainer2.should == strainer
  end
  
  it "has the full path prepended with the gitorious.yml file setting" do
    strainer = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'").parse!
    strainer.full_path.should == 
      File.join(GitoriousConfig["repository_base_path"], "foo", "bar.git")
  end
  
  it "sets the path of the parsed command" do
    cmd = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'").parse!
    cmd.path.should == "foo/bar.git"
  end

  
end