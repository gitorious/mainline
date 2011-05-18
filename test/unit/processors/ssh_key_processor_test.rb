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


require File.dirname(__FILE__) + '/../../test_helper'

class SshKeyProcessorTest < ActiveSupport::TestCase

  def setup
    SshKey.any_instance.stubs(:valid_key_using_ssh_keygen?).returns(true)
    @processor = SshKeyProcessor.new
    @key = Factory.create(:ssh_key, :ready => false)
  end
  
  should "add to authorized keys" do
    assert !@key.ready?
    SshKey.expects(:add_to_authorized_keys).with('fofofo')
    options = {
      :target_class => 'SshKey', 
      :command => 'add_to_authorized_keys', 
      :arguments => ['fofofo'],
      :target_id => @key.id}
    json = options.to_json
    @processor.consume(json)

    assert @key.reload.ready?
  end
  
  should "remove from authorized keys" do
    SshKey.expects(:delete_from_authorized_keys).with('fofofo')
    options = {
      :target_class => 'SshKey',
      :command => 'delete_from_authorized_keys',
      :arguments => ['fofofo']
    }
    json = options.to_json
    @processor.consume(json)
  end
end
