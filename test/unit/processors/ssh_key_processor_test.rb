# encoding: utf-8
#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2009 Marius Mathiesen <marius.mathiesen@gmail.com>
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
    @processor = SshKeyProcessor.new
  end
  
  should "add to authorized keys" do
    ssh_key = mock
    ssh_key.expects(:ready=).returns(true)
    ssh_key.expects(:save!).once.returns(true)
    SshKey.stubs(:find_by_id).with(1).returns(ssh_key)
    SshKey.expects(:add_to_authorized_keys).with('fofofo')
    options = {
      :target_class => 'SshKey', 
      :command => 'add_to_authorized_keys', 
      :arguments => ['fofofo'],
      :target_id => '1'}
    json = options.to_json
    @processor.on_message(json)
  end
  
  should "remove from authorized keys" do
    SshKey.expects(:delete_from_authorized_keys).with('fofofo')
    options = {
      :target_class => 'SshKey',
      :command => 'delete_from_authorized_keys',
      :arguments => ['fofofo']
    }
    json = options.to_json
    @processor.on_message(json)
  end
end
