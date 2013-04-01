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

class DestroySshKeyTest < ActiveSupport::TestCase
  include SshKeyTestHelper

  def setup
    @hub = MessageHub.new
    @uc = DestroySshKey.new(@hub)
    SshKeyValidator.any_instance.stubs(:valid_key_using_ssh_keygen?).returns(true)
  end

  should "remove SSH key" do
    ssh_key = SshKey.first
    outcome = @uc.execute(:ssh_key => ssh_key)
    assert outcome.success?, outcome.to_s
    assert_nil SshKey.find_by_id(ssh_key.id)
  end

  should "remove SSH key by id" do
    ssh_key = SshKey.first
    outcome = @uc.execute(:ssh_key_id => ssh_key.id)
    assert outcome.success?, outcome.to_s
  end

  should "publish a message to the message queue" do
    outcome = @uc.execute(:ssh_key => SshKey.first)

    assert outcome.success?
    assert_equal 1, @hub.messages.length
    expected = { :queue => "/queue/GitoriousDestroySshKey", :message => { :key => outcome.result.to_key } }
    assert_equal(expected, @hub.messages.first)
  end

  should "fail for invalid key" do
    assert_no_difference "SshKey.count" do
      outcome = @uc.execute(:ssh_key => SshKey.new(:key => invalid_key))
      refute outcome.success?
    end
  end
end
