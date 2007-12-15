require File.dirname(__FILE__) + '/../spec_helper'
require "fileutils"

describe SshKeyFile do
  
  before(:each) do
    FileUtils.cp(File.join(fixture_path, "authorized_keys"), fixture_key_path)    
    @keyfile = SshKeyFile.new(fixture_key_path)
    @keydata = ssh_keys(:johan).to_key
  end
  
  after(:each) do
    FileUtils.rm(fixture_key_path)
  end

  it "initializes with the path to the key file" do
    keyfile = SshKeyFile.new("foo/bar")
    keyfile.path.should == "foo/bar"
  end
  
  it "defaults to $HOME/.ssh/authorized_keys" do
    keyfile = SshKeyFile.new
    keyfile.path.should == File.join(File.expand_path("~"), ".ssh", "authorized_keys")
  end
  
  it "reads all the data in the file" do
    @keyfile.contents.should == File.read(fixture_key_path)
  end
  
  it "adds a key to the authorized_keys file" do
    @keyfile.add_key(@keydata)
    @keyfile.contents.should include(@keydata)
  end
  
  it "deletes a key from the file" do
    @keyfile.add_key(@keydata)
    @keyfile.delete_key(@keydata)
    @keyfile.contents.should_not include(@keydata)
    @keyfile.contents.should == File.read(File.join(fixture_path, "authorized_keys"))
  end
  
  it "doesn't rewrite the file unless the key to delete is in there" do
    File.should_not_receive(:open)
    @keyfile.delete_key(@keydata)
  end
  
  protected
    def fixture_key_path
      File.join(fixture_path, "authorized_keys_fixture")
    end

end