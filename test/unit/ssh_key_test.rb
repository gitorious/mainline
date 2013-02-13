# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class SshKeyTest < ActiveSupport::TestCase

  def new_key(opts={})
    SshKey.new({
      :user_id => 1,
      :key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com",
    }.merge(opts))
  end

  def setup
    SshKey.any_instance.stubs(:valid_key_using_ssh_keygen?).returns(true)
  end

  def teardown
    clear_message_queue
  end

  should validate_presence_of(:user_id)
  should validate_presence_of(:key)

  should "validate the key using ssh-keygen" do
    key = new_key
    key.expects(:valid_key_using_ssh_keygen?).returns(false)
    assert !key.valid?
  end

  should "only allow unique ssh keys across the whole site" do
    key = new_key
    key.save
    key2 = new_key
    assert !key2.valid?
  end

  should "have a valid ssh key" do
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

    key.key = 'ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE foo@steak_house.local'
    assert key.valid?
  end

  should "detect attempts at uploading private key" do
    key = new_key
    key.key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,1DC94B2CF7645048FE51180FFE1D4E21

0MBiH+QZutHvnUGow5zJDWEGgBWf2zd9wot05yWL26UMqyL8/Dw5mmabhFQUtEV7
pGbiceUoMCcNeQt4Wyl31gzMLzrHBgyOzDzl0Aghm1ike9QIHpoNqPjs54gGeDkZ
Qw0ZBcav+vxCXbr0Ei9igJz7i1hXYAB6U2KBTjJPfUrphGQYwZgXwVWPQRIOTfAc
4kZz0d2pj3QRxwi16UY9QO2h0rIWFbuo9iBvH6eh+cZ11t3wa84m5tKOSflJ2pYB
GoO564QLCiuLKQgmzLyP6Vv98vELUS8kO4uaKNpIMLPw0wufqQwncmyvszU87bGH
hxrJHinQ1nVNO/4sBfZnqxaRRCL+H5ykYbfYwwI8WB7uDp9uRHWW/dMOZOwpW4n/
6Z5PqXb0rk/tbN4jzjtFEqBl0DGIH+1VtrHi6yV0lzu2sKpeABqYUs0Ow6HuIgUo
I3LgLpS0TTknfEp0BaRXoJHwOryPnOVcAHP9OCXHzVMLXER2IZp+A/OC835zrlwa
YSiR3B8aR2Y8HJtakYKKRAWugTMgzTchxwUGCq7cV8gmUSE8NN1C0I6aUtX/dzGG
2Y4ZrUXdu9yYbfyua7DNUOld20tZz5xAjyaPW5Eab83uZ3AGdIpjBpKzhg0mQoZU
3QRi6PbvRY/8wgkl2It6BjWB+jXam2b3Ohp8Ck0Mj+NxcYmwaUwROOeIgTQryGb/
aZ6c6QU3WTm8ArqYpnkWpRoWGKtYFVGBXio0zQDyoTGaFYRteNak111Yp0MwSr/0
muTXn+IJM3IetIG1BjEHGcFUnaHQdeyyarZfbRJDHv+N1rA6IFiyGhBeQTYPAIjE
234ssMEtr8zlEiw161QE9Clr4lJPn0K+ApVxy+XAfseViYy1O7UlH5p8Zd7lne25
SjReCC335MGrHOzGrEVQPrSd7+V9GjhyaDHW8bc4zN4XTjl1eH5sggw3IAVyHvaE
mwwokxd6CWq2feVnJQ87FrEvnnyEpeLlVmjEi3ilk7hIcaovghV4rHoGOIz+IJi6
GsLH6/XthvZQVuWM9zm7wdV8hnB9aMdCqDjaFM0Sw3tG1CxzHGUMTG90KiSAhmgd
7nDjiRzEDHBuZAohOlV4I64c+u7AVEF048YluvXaF2xTFV8MiNdq9Zrk8BeOCQLm
iNTFKHGiIRoTFvHyTN3yLBPvZxi/x1LZfwqp5/4t7JWkCbtPeIQWuo7FdkQun9yD
+XF48dSpAaK7SVTP8LF2vPZAwlMVUOUweWtcHHIg/TABnW8n0hnOVxBvhJc+QsMk
15OSPtUc9r6iwukLMchUKp4GdIUKLMsOiDHtyfyPc+o0zYTK6/GQp4QQrivIzu+O
LBsbL8jOE8ZzjT1sbGMNHpZ51QMCv3/MeInFYt1B+qIb602cfwN92qvQaEUGrfzy
RzglIvZrIOSmH0qd/JMru4gRiSKC6obKCPlQrSV2CUSHNAKsgCmHYp/3hVtORoDk
p+OnyyDIYAbaOuiQMN5iflmKOsjU0IaNQ+NZxTql1CEmoSqg6cr+UM+qoJMOU9dA
v5wH0IF6onF/Gq+B1eWCYpjTAz7zPzkUm1MNfYDAjQox5H5DFdb5Q/pGeUiUFS4O
-----END RSA PRIVATE KEY-----
EOF

    assert !key.valid?
    assert_match "private", key.errors[:key].join("")
  end

  should "allows a wider range of extended comments" do
    key = new_key

    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE #{Gitorious.host} key"
    assert key.valid?

    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE joe+#{Gitorious.host} key"
    assert key.valid?

    key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE #{Gitorious.scheme}://#{Gitorious.host} key"
    assert key.valid?
  end

  should "cant contain multiple keys" do
    encoded_key = "bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU="
    k = "ssh-rsa #{encoded_key} foo@example.com"
    ssh = new_key(:key => "#{k}\r#{k}")
    assert ssh.valid?
    assert_equal "ssh-rsa", ssh.algorithm
    assert_equal encoded_key, ssh.encoded_key
    assert_equal "ssh-rsa #{encoded_key}", ssh.to_keyfile_format.split(" ")[0..1].join(" ")
    ssh = new_key(:key => "#{k}\n#{k}")
    assert ssh.valid?
    assert_equal "ssh-rsa", ssh.algorithm
    assert_equal encoded_key, ssh.encoded_key
    assert_equal "ssh-rsa #{encoded_key}", ssh.to_keyfile_format.split(" ")[0..1].join(" ")
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

  should "wraps the key at 72 columns for display" do
    ssh = new_key
    expected_wrapped = <<EOS
ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dk
anB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216
ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com
EOS
    assert_equal expected_wrapped.strip, ssh.wrapped_key
  end

  should "return the algorithm and encoded key with our own comment with to_keyfile" do
    key = new_key
    key.save!
    expected_format = "#{key.algorithm} #{key.encoded_key} SshKey:#{key.id}-User:#{key.user_id}"
    assert_equal expected_format, key.to_keyfile_format
  end

  should "returns a proper ssh key with to_key" do
    ssh_key = new_key
    ssh_key.save!
    exp_key = %Q{### START KEY #{ssh_key.id} ###\n} +
      %Q{command="gitorious #{users(:johan).login}",no-port-forwarding,} +
      %Q{no-X11-forwarding,no-agent-forwarding,no-pty #{ssh_key.to_keyfile_format}} +
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

  def key_with_content(algo = nil, key = nil, comment = nil)
    algo ||= "ssh-rsa"
    key ||= "bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU="
    comment ||= "foo@bar.com"
    new_key({
      :key => "#{algo} #{key} #{comment}",
    })
  end

  context "Parsing the key" do
    should "parse out the key into its components" do
      assert_equal 3, new_key.components.size
      key = key_with_content(nil, nil, "the quick brown fox jumped")
      assert_equal 3, key.components.size
      assert_equal "the quick brown fox jumped", key.components.last
      assert_nothing_raised do
        key.key = nil
        key.components
      end
    end

    should "parse out the algorithm" do
      assert_equal "ssh-rsa", new_key.algorithm
    end

    should "parse out the username+host comment" do
      assert_equal "foo@example.com", new_key.comment
    end

    should "parse out the content" do
      expected_content = "bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU="
      assert_equal expected_content, new_key.encoded_key
    end
  end

  should "have a fingerprint" do
    ssh_key = new_key(:key => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6LbBnTQ9qnLxvvl" +
      "Jy3Qc7CXlTLWq7R335hhBl2+IPN+dzp1/Dg9LYNb3BRhoQUKVbuq2t8Nw7uj1856kNuH9/zjppHi" +
      "iqMYK60ZP3w/q6S29iEExtVB+vNOZxsL9biVIQFJOPvbTxxqd8185apPLICcfZlb6iougbmHoU3u" +
      "BKJXa8ViQgLiOmnO/E2jyT60E9WAUGFyJpCopjRiOMR7OJ2mHDtOTyDLLJtL2+nFfLPJIryz2WNq" +
      "BlwPtWowM3QEeSgrQUziDoGLrBorEmvSfXMPSjOXUOQmTzZeWvR7OoL0YlwxByqka3qrklUX+cLe" +
      "74YL6aTrfAHTXXJ7fcMDZxQ== foo@bar")
    assert_equal "9b:72:ec:61:35:08:56:c1:95:8c:fd:dd:32:66:ab:8a", ssh_key.fingerprint
  end

  context "Message sending" do
    should 'send a message when created' do
      ssh_key = new_key
      ssh_key.save!
      ssh_key.publish_creation_message

      assert_published("/queue/GitoriousSshKeys", {
                         "command" => "add_to_authorized_keys",
                         "arguments" => [ssh_key.to_key],
                         "target_id" => ssh_key.id
                       })
    end

    should "not allow publishing messages for new records" do
      ssh_key = new_key
      assert_raises ActiveRecord::RecordInvalid do
        ssh_key.publish_creation_message
      end
    end

    should 'sends a message on destroy' do
      ssh_key = new_key
      ssh_key.save!
      keydata = ssh_key.to_key.dup
      ssh_key.destroy

      assert_published("/queue/GitoriousSshKeys", {
                         "identifier" => "ssh_key_#{ssh_key.id}",
                         "command" => "delete_from_authorized_keys",
                         "arguments" => [keydata]
                       })
    end
  end
end
