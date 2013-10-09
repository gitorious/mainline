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
    @ssh_key = new_key
    @ssh_key.save
    @uc = DestroySshKey.new(@hub, @ssh_key.user)
    SshKeyValidator.any_instance.stubs(:valid_key_using_ssh_keygen?).returns(true)
  end

  should "remove SSH key" do
    outcome = @uc.execute(:id => @ssh_key.id)
    assert outcome.success?, outcome.to_s
    assert_nil SshKey.find_by_id(@ssh_key.id)
  end

  should "publish a message to the message queue" do
    outcome = @uc.execute(:id => @ssh_key.id)

    assert outcome.success?, outcome.to_s
    assert_equal 1, @hub.messages.length
    keydata = SshKeyFile.format(@ssh_key)
    expected = { :queue => "/queue/GitoriousDestroySshKey", :message => { :data => keydata } }
    assert_equal(expected, @hub.messages.first)
  end

  should "fail for invalid key" do
    assert_raises ActiveRecord::RecordNotFound do
      @uc.execute(:id => SshKey.new(:key => invalid_key))
    end
  end

  should "fail when attempting to remove key not belonging to user" do
    ssh_key = new_key(:user => users(:moe))
    ssh_key.save
    assert_raises ActiveRecord::RecordNotFound do
      @uc.execute(:id => ssh_key.id)
    end
  end
end
