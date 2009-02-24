# encoding: utf-8
#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
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


require File.dirname(__FILE__) + '/../../test_helper'
require "gitorious/ssh/client"
require "gitorious/ssh/strainer"

class SSHStrainerTest < ActiveSupport::TestCase
  
  should "raises if command includes a newline" do
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("foo\nbar").parse!
    end
  end
  
  should "raises if command has more than one argument" do
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack 'bar baz'").parse!
    end
  end
  
  should "raises if command doesn't have an argument" do
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack").parse!
    end
  end
  
  should "raises if it gets a bad command" do
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("evil 'foo'").parse!
    end
  end
  
  should "raises if it receives an unsafe argument" do
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack /evil/attack").parse!
    end
  end
  
  should "raises if it receives an unsafe argument that almost looks kosher" do
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack '/evil/path'").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack '+/evil/path'").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack '~/evil/path'").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack /evil/\\\\\\//path").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack +/evil/\\\\\\//path").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack ~/evil/\\\\\\//path").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack ../../evil/path").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack 'evil/path.git.bar'").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack +../../evil/path").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack ~../../evil/path").parse!
    end
  end
  
  should "raises if it receives an empty path" do
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack ''").parse!
    end
    
    assert_raises(Gitorious::SSH::BadCommandError) do
      Gitorious::SSH::Strainer.new("git-upload-pack ").parse!
    end
  end
  
  should "returns self when running #parse" do
    strainer = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'")
    strainer2 = strainer.parse!
    assert_instance_of Gitorious::SSH::Strainer, strainer2
    assert_equal strainer, strainer2
  end
  
  should "sets the path of the parsed command" do
    cmd = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'").parse!
    assert_equal "foo/bar.git", cmd.path
  end

  should "can parse user-style urls prefixed with a tilde" do
    assert_nothing_raised(Gitorious::SSH::BadCommandError) do
      cmd = Gitorious::SSH::Strainer.new("git-upload-pack '~foo/bar.git'").parse!
      assert_equal "~foo/bar.git", cmd.path
    end
  end
  
  should "can parse team-style urls prefixed with a plus" do
    assert_nothing_raised(Gitorious::SSH::BadCommandError) do
      cmd = Gitorious::SSH::Strainer.new("git-upload-pack '+foo/bar.git'").parse!
      assert_equal "+foo/bar.git", cmd.path
    end
  end
  
  should "can parse user-style urls with project name and prefixed with a tilde" do
    assert_nothing_raised(Gitorious::SSH::BadCommandError) do
      cmd = Gitorious::SSH::Strainer.new("git-upload-pack '~foo/bar/baz.git'").parse!
      assert_equal "~foo/bar/baz.git", cmd.path
    end
  end
  
  should "can parse team-style urls with project name and prefixed with a plus" do
    assert_nothing_raised(Gitorious::SSH::BadCommandError) do
      cmd = Gitorious::SSH::Strainer.new("git-upload-pack '+foo/bar/baz.git'").parse!
      assert_equal "+foo/bar/baz.git", cmd.path
    end
  end
end
