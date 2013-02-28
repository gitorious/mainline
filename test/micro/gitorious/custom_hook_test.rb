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
require "gitorious/custom_hook"

class CustomHookTest < MiniTest::Shoulda
  should "use executable script in data/hooks" do
    File.stubs(:executable?).returns(true)
    hook = Gitorious::CustomHook.new("pre-receive")

    expected = File.join(Rails.root, "data/hooks/custom-pre-receive")
    assert_equal File.expand_path(expected), hook.path
  end

  should "use configured script" do
    File.stubs(:executable?).returns(false)
    Gitorious::Configuration.override("custom_pre_receive_hook" => "/tmp/cpr") do
      hook = Gitorious::CustomHook.new("pre-receive")

      assert_equal "/tmp/cpr", hook.path
    end
  end

  should "execute script without arguments" do
    File.stubs(:executable?).returns(false)
    File.stubs(:executable?).with("/tmp/cpr").returns(true)
    Gitorious::Configuration.override("custom_pre_receive_hook" => "/tmp/cpr") do
      hook = Gitorious::CustomHook.new("pre-receive")

      IO.expects(:popen).with("/tmp/cpr 2>&1", "w+")
      hook.execute([], "Something")
    end
  end

  should "execute script with arguments" do
    File.stubs(:executable?).returns(false)
    File.stubs(:executable?).with("/tmp/cpr").returns(true)
    Gitorious::Configuration.override("custom_pre_receive_hook" => "/tmp/cpr") do
      hook = Gitorious::CustomHook.new("pre-receive")

      IO.expects(:popen).with("/tmp/cpr aaaa bbbb refs/heads/master 2>&1", "w+")
      hook.execute(["aaaa", "bbbb", "refs/heads/master"], "Something")
    end
  end
end
