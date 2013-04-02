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

class NewSshKeyProcessorTest < ActiveSupport::TestCase
  include SshKeyTestHelper

  should "add key to the authorized keys file" do
    ssh_key = new_key
    ssh_key.save!
    SshKeyFile.any_instance.expects(:add_key).with(SshKeyFile.format(ssh_key)).returns(true)

    NewSshKeyProcessor.new.on_message("id" => ssh_key.id)
  end

  should "not add non-existent key to the authorized keys file" do
    SshKeyFile.any_instance.expects(:add_key).never
    NewSshKeyProcessor.new.on_message("id" => 666)
  end

  should "mark ssh key as ready" do
    ssh_key = new_key
    ssh_key.save!
    SshKeyFile.any_instance.stubs(:add_key)
    NewSshKeyProcessor.new.on_message("id" => ssh_key.id)

    assert ssh_key.reload.ready?
  end
end
