# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
require "fast_test_helper"
require "commands/enable_standby_mode_command"

class EnableStandbyModeCommandTest < MiniTest::Shoulda
  def setup
    @master_public_key = "ssh-rsa 3GeMgsBONURpIt+CdfuNmxeG...== master@puppets"

    @base_path = File.join(Rails.root, 'tmp', 'standby-test')
    FileUtils.mkdir_p(@base_path)

    @authorized_keys_path = File.join(@base_path, 'authorized_keys')
    File.open(@authorized_keys_path, 'w') { |f| f.write('qux') }

    @public_path = File.join(@base_path, 'public')
    FileUtils.mkdir_p(File.join(@public_path, 'system'))

    @global_hooks_path = File.join(@base_path, 'hooks')
    old_hooks_path = File.join(@base_path, 'the-hooks')
    FileUtils.mkdir_p(old_hooks_path)
    FileUtils.ln_s(old_hooks_path, @global_hooks_path)

    @command = EnableStandbyModeCommand.new(@public_path, @authorized_keys_path,
                                            @global_hooks_path)
  end

  def teardown
    FileUtils.rm_rf(@base_path)
  end

  def execute_command
    Gitorious::Configuration.override('master_public_key' => @master_public_key) do
      @command.execute
    end
  end

  context "#execute" do
    should "enable the standby page" do
      execute_command

      assert File.symlink?(File.join(@public_path, 'system', 'standby.html'))
    end

    should "disable all the git hooks" do
      execute_command

      assert_equal '/dev/null', File.readlink(@global_hooks_path)
    end

    should "generate authorized_keys to include public key of master instance user" do
      SshKeyFile.expects(:format_master_key).with(@master_public_key).returns('foo')
      execute_command

      assert_equal 'foo', File.read(@authorized_keys_path)
    end
  end
end
