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

require File.dirname(__FILE__) + '/../spec_helper'

describe SshKey do
  
  def new_key(opts={})
    SshKey.new({
      :user_id => 1,
      :key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com",
    }.merge(opts))
  end

  it "should have a valid ssh key" do
    key = new_key
    key.key = ""
    key.should_not be_valid
    key.key = "foo bar@baz"
    key.should_not be_valid
    
    key.key = "ssh-somealgo as23d$%&asdasdasd bar@baz"
    key.should_not be_valid
    
    key.key = "ssh-rsa asdasda2\n34as+d=\n bar@baz"
    key.should be_valid
    key.key = "ssh-rsa asdasda2\n34as+d=\n bar@baz.grogg.zing"
    key.should be_valid    
    key.key = "ssh-rsa asdasda2\n34as+d=\n bar@127.0.0.1"
    key.should be_valid
    
    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE foo@steakhouse.local"
    key.should be_valid
  end
  
  it "allows a wider range of extended comments" do
    key = new_key
    
    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE #{GitoriousConfig['gitorious_host']} key"
    key.should be_valid
    
    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE joe+#{GitoriousConfig['gitorious_host']} key"
    key.should be_valid
    
    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE http://#{GitoriousConfig['gitorious_host']} key"
    key.should be_valid
  end
  
  it "should have a user to be valid" do
    key = new_key
    key.user_id = nil
    key.should_not be_valid
    
    key.user_id = users(:johan).id
    key.valid?
    key.should be_valid
  end
  
  it "cant contain multiple keys" do
    k = "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com"
    key = "#{k}\r#{k}"
    ssh = new_key(:key => key)
    ssh.should_not be_valid
  end
  
  it "strips newlines before save" do
    ssh = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\n9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")
    ssh.valid?
    ssh.key.should_not include("\n")
    
    ssh = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\r\n9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")
    ssh.valid?
    ssh.key.should_not include("\r\n")
    
    ssh = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\r9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")
    ssh.valid?
    ssh.key.should_not include("\r")
  end
  
  it "strips beginning and ending whitespace+newlines before validation" do
    ssh = new_key(:key => "\n ssh-rsa asdfsomekey foo@example.com  \n  ")
    ssh.valid?.should == true
    ssh.key.should == "ssh-rsa asdfsomekey foo@example.com"
  end
    
  it "wraps the key at 72 for display" do
    ssh = new_key
    expected_wrapped = <<EOS
ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dk
anB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216
ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com 
EOS
    ssh.wrapped_key.should == expected_wrapped.strip
  end
  
  it "returns a proper ssh key with to_key" do
    ssh_key = new_key
    ssh_key.save!
    exp_key = %Q{### START KEY #{ssh_key.id} ###\n} + 
      %Q{command="gitorious #{users(:johan).login}",no-port-forwarding,} + 
      %Q{no-X11-forwarding,no-agent-forwarding,no-pty #{ssh_key.key}} + 
      %Q{\n### END KEY #{ssh_key.id} ###\n}
    ssh_key.to_key.should == exp_key
  end
  
  it "adds itself to the authorized keys file" do
    ssh_key_file_mock = mock("SshKeyFile mock")
    ssh_key = new_key
    ssh_key_file_mock.expects(:new).returns(ssh_key_file_mock)
    ssh_key_file_mock.expects(:add_key).with(ssh_key.to_key).returns(true)
    SshKey.add_to_authorized_keys(ssh_key.to_key, ssh_key_file_mock)
  end
  
  it "removes itself to the authorized keys file" do
    ssh_key_file_mock = mock("SshKeyFile mock")
    ssh_key = new_key
    ssh_key_file_mock.expects(:new).returns(ssh_key_file_mock)
    ssh_key_file_mock.expects(:delete_key).with(ssh_key.to_key).returns(true)
    SshKey.delete_from_authorized_keys(ssh_key.to_key, ssh_key_file_mock)
  end
  
  it "creates a Task on create and update" do
    ssh_key = new_key
    proc{
      ssh_key.save!
    }.should change(Task, :count)
    task = Task.find(:first, :conditions => ["target_class = 'SshKey'"], :order => "id desc")
    task.command.should == "add_to_authorized_keys"
    task.arguments.should == [ssh_key.to_key]
    task.target_id.should == ssh_key.id
  end
  
  it "creates a Task on destroy" do
    ssh_key = new_key
    ssh_key.save!
    keydata = ssh_key.to_key.dup
    proc{
      ssh_key.destroy
    }.should change(Task, :count)
    task = Task.find(:first, :conditions => ["target_class = 'SshKey'"], :order => "id desc")
    task.command.should == "delete_from_authorized_keys"
    task.arguments.should == [keydata]
  end
end
