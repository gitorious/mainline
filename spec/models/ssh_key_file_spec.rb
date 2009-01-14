#--
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

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
    File.expects(:open).never
    @keyfile.delete_key(@keydata)
  end
  
  protected
    def fixture_key_path
      File.join(fixture_path, "authorized_keys_fixture")
    end

end