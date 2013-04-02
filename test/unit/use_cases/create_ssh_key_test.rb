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
require "ssh_key_test_helper"

class CreateSshKeyTest < ActiveSupport::TestCase
  include SshKeyTestHelper

  def setup
    @hub = MessageHub.new
    @user = users(:moe)
    @uc = CreateSshKey.new(@hub, @user)
    SshKeyValidator.any_instance.stubs(:valid_key_using_ssh_keygen?).returns(true)
  end

  should "create new SSH key for user" do
    count = @user.ssh_keys.count
    outcome = @uc.execute(:key => valid_key)
    assert outcome.success?, outcome.to_s
    assert_equal count + 1, @user.ssh_keys.count
  end

  should "publish a creation message to the message queue" do
    outcome = @uc.execute(:key => valid_key)

    assert outcome.success?
    assert_equal 1, @hub.messages.length
    expected = { :queue => "/queue/GitoriousNewSshKey", :message => { :id => outcome.result.id } }
    assert_equal(expected, @hub.messages.first)
  end

  should "fail for invalid key" do
    assert_no_difference "SshKey.count" do
      outcome = @uc.execute(:key => invalid_key)
      refute outcome.success?
      refute_nil outcome.failure.errors[:key]
    end
  end

  should "fail for missing user" do
    assert_no_difference "SshKey.count" do
      outcome = CreateSshKey.new(@hub, nil).execute(:key => valid_key)
      refute outcome.success?, outcome.inspect
      assert outcome.pre_condition_failed?, outcome.inspect
    end
  end
end
