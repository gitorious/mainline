# encoding: utf-8
#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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

require File.dirname(__FILE__) + '/../test_helper'
require "fileutils"

class SshKeyFileTest < ActiveSupport::TestCase

  def fixture_key_path
    File.join(fixture_path, "authorized_keys_fixture")
  end

  def setup
    FileUtils.cp(File.join(fixture_path, "authorized_keys"), fixture_key_path)
    @keyfile = SshKeyFile.new(fixture_key_path)
    @keydata = ssh_keys(:johan).to_key
  end

  def teardown
    FileUtils.rm(fixture_key_path) if File.exist?(fixture_key_path)
  end

  should "initializes with the path to the key file" do
    keyfile = SshKeyFile.new("foo/bar")
    assert_equal "foo/bar", keyfile.path
  end

  should "defaults to $HOME/.ssh/authorized_keys" do
    keyfile = SshKeyFile.new
    assert_equal File.join(File.expand_path("~"), ".ssh", "authorized_keys"), keyfile.path
  end

  should "reads all the data in the file" do
    assert_equal File.read(fixture_key_path), @keyfile.contents
  end

  should "adds a key to the authorized_keys file" do
    @keyfile.add_key(@keydata)
    assert @keyfile.contents.include?(@keydata)
  end

  should "add a key to unexistent authorized_keys file and initialize file permission's
correctly" do
    path = File.dirname(__FILE__) + '/../../tmp/keyfile'
    keyfile = SshKeyFile.new(path)
    keyfile.add_key(@keydata)
    #33152 is the binary representation of only user read write permission
    assert_equal 33152, File::Stat.new(path).mode
    FileUtils.rm(path)
  end

  should "deletes a key from the file" do
    @keyfile.add_key(@keydata)
    @keyfile.delete_key(@keydata)
    assert !@keyfile.contents.include?(@keydata)
    assert_equal File.read(File.join(fixture_path, "authorized_keys")), @keyfile.contents
  end

  should "doesn't rewrite the file unless the key to delete is in there" do
    File.expects(:open).never
    @keyfile.delete_key(@keydata)
  end

end
