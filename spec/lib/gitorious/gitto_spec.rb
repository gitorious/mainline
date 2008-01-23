require File.dirname(__FILE__) + '/../../spec_helper'
require "ostruct"

describe Gitorious::Gitto do
  
  before(:each) do
    @path = "/home/repositories/foo"
    @git_mock = mock("Git mock")
    Git.should_receive(:bare).with(@path).and_return(@git_mock)
    @gitto = Gitorious::Gitto.new(@path)
  end
  
  def some_sha(char = "a")
    char * 40
  end
  
  it "should return Git#log(10)" do
    @git_mock.should_receive(:log).with(10, nil).and_return([])
    @gitto.log(10)
  end
  
  it "returns Git#log(10,20)" do
    @git_mock.should_receive(:log).with(10, 20).and_return([])
    @gitto.log(10, 20)
  end
  
  it "returns Git#gtre" do
    @git_mock.should_receive(:gtree).with(some_sha).and_return(mock("tree"))
    @gitto.should_receive(:check_sha).with(some_sha)
    @gitto.tree(some_sha)
  end
  
  it "return Git#gcommit" do
    @git_mock.should_receive(:gcommit).with(some_sha).and_return(mock("commit"))
    @gitto.should_receive(:check_sha).with(some_sha)
    @gitto.commit(some_sha)
  end
  
  it "return Git#diff" do
    @git_mock.should_receive(:diff).with(some_sha("a"), some_sha("b")).and_return(mock("diff"))
    @gitto.should_receive(:check_sha).with(some_sha("a"))
    @gitto.should_receive(:check_sha).with(some_sha("b"))
    @gitto.diff(some_sha("a"), some_sha("b"))
  end
  
  it "return Git#gblob" do
    @git_mock.should_receive(:gblob).with(some_sha).and_return(mock("blob"))
    @gitto.should_receive(:check_sha).with(some_sha)
    @gitto.blob(some_sha)
  end
  
  it "return Git#gblob" do
    @git_mock.should_receive(:gblob).with(some_sha).and_return(mock("blob"))
    @gitto.should_receive(:check_sha).with(some_sha)
    @gitto.blob(some_sha)
  end
  
  it "returns Git#tags" do
    @git_mock.should_receive(:tags).and_return([])
    @gitto.tags
  end
  
  it "returns Git#branches" do
    @git_mock.should_receive(:branches).and_return([])
    @gitto.branches
  end
  
  it "returns Git#remotes" do
    @git_mock.should_receive(:remotes).and_return([])
    @gitto.remotes
  end
  
  it "returns a list of tags grouped by sha" do
    tag1 = OpenStruct.new(:name => "tag1", :sha => some_sha("a"))
    tag2 = OpenStruct.new(:name => "tag2", :sha => some_sha("b"))
    @git_mock.should_receive(:tags).exactly(3).times.and_return([tag1, tag2])
    
    @gitto.tags_by_sha.keys.sort.should == [tag1.sha, tag2.sha]
    @gitto.tags_by_sha[tag1.sha].should == [tag1.name]
    @gitto.tags_by_sha[tag2.sha].should == [tag2.name]
  end
  
  describe "objectish validation" do
    it "accepts good objectish" do
      proc{ 
        @gitto.check_sha(some_sha) 
      }.should_not raise_error(Gitorious::Gitto::BadShaError)
      proc{ 
        @gitto.check_sha( ("a"*20) + ("2"*20) ) 
      }.should_not raise_error(Gitorious::Gitto::BadShaError)
      proc{ 
        @gitto.check_sha("HEAD") 
      }.should_not raise_error(Gitorious::Gitto::BadShaError)
      proc{ 
        @gitto.check_sha("HEAD~1") 
      }.should_not raise_error(Gitorious::Gitto::BadShaError)
      proc{ 
        @gitto.check_sha("HEAD^{1}") # valid chars at least
      }.should_not raise_error(Gitorious::Gitto::BadShaError)
      proc{ 
        @gitto.check_sha("v0.1^{tree}") 
      }.should_not raise_error(Gitorious::Gitto::BadShaError)
    end
    
    it "raises on bad objectish" do
      proc{ 
        @gitto.check_sha("asd;rm -rf") 
      }.should raise_error(Gitorious::Gitto::BadShaError)
      proc{ 
        @gitto.check_sha("asd;cat /etc/foo") 
      }.should raise_error(Gitorious::Gitto::BadShaError)
      
      proc{ 
        @gitto.check_sha("%3B++%2Ffoo") 
      }.should raise_error(Gitorious::Gitto::BadShaError)
    end
  end
  
end