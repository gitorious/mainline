# encoding: utf-8
#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
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

require File.dirname(__FILE__) + '/../test_helper'

class SshKeyTest < ActiveSupport::TestCase
  
  def new_key(opts={})
    SshKey.new({
      :user_id => 1,
      :key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com",
    }.merge(opts))
  end

  should " have a valid ssh key" do
    key = new_key
    key.key = ""
    assert !key.valid?
    key.key = "foo bar@baz"
    assert !key.valid?
    
    key.key = "ssh-somealgo as23d$%&asdasdasd bar@baz"
    assert !key.valid?
    
    key.key = "ssh-rsa asdasda2\n34as+d=\n bar@baz"
    assert key.valid?
    key.key = "ssh-rsa asdasda2\n34as+d=\n bar@baz.grogg.zing"
    assert key.valid?
    key.key = "ssh-rsa asdasda2\n34as+d=\n bar@127.0.0.1"
    assert key.valid?
    
    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE foo@steakhouse.local"
    assert key.valid?
  end
  
  should "allows a wider range of extended comments" do
    key = new_key
    
    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE #{GitoriousConfig['gitorious_host']} key"
    assert key.valid?
    
    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE joe+#{GitoriousConfig['gitorious_host']} key"
    assert key.valid?
    
    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE http://#{GitoriousConfig['gitorious_host']} key"
    assert key.valid?
  end
  
  should " have a user to be valid" do
    key = new_key
    key.user_id = nil
    assert !key.valid?
    
    key.user_id = users(:johan).id
    key.valid?
    assert key.valid?
  end
  
  should "cant contain multiple keys" do
    k = "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com"
    key = "#{k}\r#{k}"
    ssh = new_key(:key => key)
    assert !ssh.valid?
  end
  
  should "strips newlines before save" do
    ssh = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\n9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")
    ssh.valid?
    assert !ssh.key.include?("\n")
    
    ssh = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\r\n9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")
    ssh.valid?
    assert !ssh.key.include?("\r\n")
    
    ssh = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\r9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")
    ssh.valid?
    assert !ssh.key.include?("\r")
  end
  
  should "strips beginning and ending whitespace+newlines before validation" do
    ssh = new_key(:key => "\n ssh-rsa asdfsomekey foo@example.com  \n  ")
    assert ssh.valid?
    assert_equal "ssh-rsa asdfsomekey foo@example.com", ssh.key
  end
    
  should "wraps the key at 72 for display" do
    ssh = new_key
    expected_wrapped = <<EOS
ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dk
anB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216
ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com 
EOS
    assert_equal expected_wrapped.strip, ssh.wrapped_key
  end
  
  should "returns a proper ssh key with to_key" do
    ssh_key = new_key
    ssh_key.save!
    exp_key = %Q{### START KEY #{ssh_key.id} ###\n} + 
      %Q{command="gitorious #{users(:johan).login}",no-port-forwarding,} + 
      %Q{no-X11-forwarding,no-agent-forwarding,no-pty #{ssh_key.key}} + 
      %Q{\n### END KEY #{ssh_key.id} ###\n}
    assert_equal exp_key, ssh_key.to_key
  end
  
  should "adds itself to the authorized keys file" do
    ssh_key_file_mock = mock("SshKeyFile mock")
    ssh_key = new_key
    ssh_key_file_mock.expects(:new).returns(ssh_key_file_mock)
    ssh_key_file_mock.expects(:add_key).with(ssh_key.to_key).returns(true)
    SshKey.add_to_authorized_keys(ssh_key.to_key, ssh_key_file_mock)
  end
  
  should "removes itself to the authorized keys file" do
    ssh_key_file_mock = mock("SshKeyFile mock")
    ssh_key = new_key
    ssh_key_file_mock.expects(:new).returns(ssh_key_file_mock)
    ssh_key_file_mock.expects(:delete_key).with(ssh_key.to_key).returns(true)
    SshKey.delete_from_authorized_keys(ssh_key.to_key, ssh_key_file_mock)
  end
  
  
  should 'send a message on create and update' do
    ssh_key = new_key
    p = proc{
      ssh_key.save!
    }
    message = message_created_in_queue('/queue/GitoriousSshKeys', /ssh_key_#{ssh_key.id}/) {p.call}
    assert_equal 'add_to_authorized_keys', message['command']
    assert_equal [ssh_key.to_key], message['arguments']
    assert_equal ssh_key.id, message['target_id']
  end
  
  should 'sends a message on destroy' do
    ssh_key = new_key
    ssh_key.save!
    keydata = ssh_key.to_key.dup
    p = proc{
      ssh_key.destroy
    }
    message = message_created_in_queue('/queue/GitoriousSshKeys', /ssh_key_#{ssh_key.id}/) {p.call}
    assert_equal 'delete_from_authorized_keys', message['command']
    assert_equal [keydata], message['arguments']
  end
  
  def message_created_in_queue(queue_name, regexp)
    ActiveMessaging::Gateway.connection.clear_messages
    yield
    msg = ActiveMessaging::Gateway.connection.find_message(queue_name, regexp)
    assert !msg.nil?
    return ActiveSupport::JSON.decode(msg.body)    
  end
  
end
