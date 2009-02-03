#--
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
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
  
  it "sets the path of the parsed command" do
    cmd = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'").parse!
    cmd.path.should == "foo/bar.git"
  end

  
end