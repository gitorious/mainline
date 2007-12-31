require File.dirname(__FILE__) + '/../../../spec_helper'

describe Gitorious::SSH::Client do
  
  before(:each) do
    @strainer = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'").parse!
    @ok_stub = mock("ok response mock", :body => "true")
    @not_ok_stub = mock("ok response mock", :body => "false")
  end
  
  it "parses the project name from the passed in Strainer" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.project_name.should == "foo"
  end
  
  it "parses the repository name from the passed in Strainer" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.repository_name.should == "bar"
  end
  
  it "sets the username that was passed into it" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.user_name.should == "johan"
  end
  
  it "has a query_url" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    exp_url = "/p/foo/repos/bar/writable_by?username=johan"
    client.query_url.should == exp_url
  end
  
  it "asks the server if a user has permission" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = mock("connection_stub", :null_object => true)
    connection_stub.should_receive(:get) \
      .with("/p/foo/repos/bar/writable_by?username=johan") \
      .and_return(@ok_stub)
    client.should_receive(:connection).and_return(connection_stub)

    client.writable_by_user?.should == true
  end
  
  it "returns false if a user doesn't have write permissions" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = mock("connection stub", :null_object => true)
    connection_stub.should_receive(:get) \
      .with("/p/foo/repos/bar/writable_by?username=johan") \
      .and_return(@not_ok_stub)
    client.should_receive(:connection).and_return(connection_stub)

    client.writable_by_user?.should == false
  end
  
  it "assure_user_can_write! raises if a user doesn't have write permissions" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.should_receive(:writable_by_user?).and_return(false)

    proc {
      client.assure_user_can_write!
    }.should raise_error(Gitorious::SSH::AccessDeniedError)
  end
  
  it "assure_user_can_write! doesn't raise if a  user have write permissions" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.should_receive(:writable_by_user?).and_return(true)

    proc {
      client.assure_user_can_write!
    }.should_not raise_error(Gitorious::SSH::AccessDeniedError)
  end
  
  it "returns the command we can safely execute with git-shell" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    repos_path = File.join(File.expand_path("~"), "repositories", @strainer.path)
    client.to_git_shell_argument.should == "git-upload-pack '#{repos_path}'"
  end
  
end