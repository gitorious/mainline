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
require "test_helper"
require "ssh_key_creator"

class SshKeyCreatorTest < ActiveSupport::TestCase
  include KeyStubs

  def setup
    SshKey.any_instance.stubs(:valid_key_using_ssh_keygen?).returns(true)
  end

  should "create new SSH key for user" do
    SshKey.any_instance.stubs(:publish_creation_message)
    user = users(:moe)

    assert_difference "user.ssh_keys.count" do
      outcome = SshKeyCreator.run(:user_id => user.id, :key => valid_key)
      assert outcome.success?
    end
  end

  should "publish a creation message to the message queue" do
    user = users(:moe)
    SshKey.any_instance.expects(:publish_creation_message)
    assert SshKeyCreator.run(:user_id => user.id, :key => valid_key).success?
  end

  should "fail for duplicate key" do
    SshKey.any_instance.stubs(:publish_creation_message)
    user = users(:moe)
    SshKeyCreator.run(:user_id => user.id, :key => valid_key)

    assert_no_difference "user.ssh_keys.count" do
      outcome = SshKeyCreator.run(:user_id => user.id, :key => valid_key)
      refute outcome.success?
      refute_nil outcome.errors.message[:key]
    end
  end

  should "fail for missing user" do
    SshKey.any_instance.stubs(:publish_creation_message)

    assert_no_difference "SshKey.count" do
      outcome = SshKeyCreator.run(:key => valid_key)
      refute outcome.success?
      refute_nil outcome.errors.message["user_id"]
    end
  end
end
