# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "ssh_key_test_helper"
require "fileutils"

class SshKeyFileTest < ActiveSupport::TestCase
  include SshKeyTestHelper

  def fixture_key_path
    File.join(fixture_path, "authorized_keys_fixture")
  end

  def setup
    FileUtils.cp(File.join(fixture_path, "authorized_keys"), fixture_key_path)
    @keyfile = SshKeyFile.new(fixture_key_path)
    @keydata = SshKeyFile.format(ssh_keys(:johan))
  end

  def teardown
    FileUtils.rm(fixture_key_path) if File.exist?(fixture_key_path)
    ENV.delete("GITORIOUS_AUTHORIZED_KEYS_PATH")
  end

  should "initializes with the path to the key file" do
    keyfile = SshKeyFile.new("foo/bar")
    assert_equal "foo/bar", keyfile.path
  end

  should "defaults to $HOME/.ssh/authorized_keys" do
    keyfile = SshKeyFile.new
    assert_equal File.join(File.expand_path("~"), ".ssh", "authorized_keys"), keyfile.path
  end

  should "read the default path from ENV" do
    ENV["GITORIOUS_AUTHORIZED_KEYS_PATH"] = "/var/lib/gitorious"

    assert_equal "/var/lib/gitorious", SshKeyFile.new.path
  end

  should "reads all the data in the file" do
    assert_equal File.read(fixture_key_path), @keyfile.contents
  end

  should "truncate the file to zero length" do
    @keyfile.truncate!

    assert_equal '', File.read(fixture_key_path)
  end

  should "not create a new file if the file doesn't exist" do
    File.unlink(fixture_key_path)

    @keyfile.truncate!

    assert !File.exist?(fixture_key_path)
  end

  should "adds a key to the authorized_keys file" do
    @keyfile.add_key(@keydata)
    assert @keyfile.contents.include?(@keydata)
  end

  should "deletes a key from the file" do
    @keyfile.add_key(@keydata)
    @keyfile.delete_key(@keydata)
    assert !@keyfile.contents.include?(@keydata)
    assert_equal File.read(File.join(fixture_path, "authorized_keys")), @keyfile.contents
  end

  should "does not rewrite the file unless the key to delete is in there" do
    File.expects(:open).never
    @keyfile.delete_key(@keydata)
  end

  context "non-existent authorized_keys file" do
    setup { @path = File.dirname(__FILE__) + "/../../tmp/keyfile" }
    teardown { FileUtils.rm(@path) }

    should "add a key and initialize file permissions correctly" do
      keyfile = SshKeyFile.new(@path)
      keyfile.add_key(@keydata)

      binary_rw_permissions = 33152
      assert_equal 33152, File::Stat.new(@path).mode
    end
  end

  context "format" do
    setup do
      @key = new_key
      @key.save! # Formatting uses the id from the saved record
    end

    should "include algorithm, encoded key and custom comment" do
      expected = /#{@key.algorithm} #{@key.encoded_key} SshKey:#{@key.id}-User:#{@key.user_id}/

      assert_match expected, SshKeyFile.format(@key)
    end

    should "produce a proper ssh key" do
      keyfile_format = "#{@key.algorithm} #{@key.encoded_key} SshKey:#{@key.id}-User:#{@key.user_id}"
      exp_key = "### START KEY #{@key.id} ###\n" +
        "command=\"gitorious #{users(:johan).login}\",no-port-forwarding," +
        "no-X11-forwarding,no-agent-forwarding,no-pty #{keyfile_format}" +
        "\n### END KEY #{@key.id} ###\n"

      assert_equal exp_key, SshKeyFile.format(@key)
    end
  end

  context "format_master_key" do
    should "produce a proper ssh key" do
      key = "ssh-rsa 3GeMgsBONURpIt+CdfuNmxeG...== master@puppets"
      exp_key = "### START KEY master ###\n" +
        "command=\"gitorious-mirror\",no-port-forwarding," +
        "no-X11-forwarding,no-agent-forwarding,no-pty #{key}\n" +
        "### END KEY master ###\n"

      assert_equal exp_key, SshKeyFile.format_master_key(key)
    end
  end

  context "regenerate" do
    should "regenerate authorized_keys file to include ready user keys" do
      key = SshKey.new(:user => User.new)
      SshKey.expects(:ready).returns([key])
      SshKeyFile.expects(:format).with(key).returns('the key')

      SshKeyFile.regenerate(fixture_key_path)

      assert_equal 'the key', File.read(fixture_key_path)
    end
  end
end
