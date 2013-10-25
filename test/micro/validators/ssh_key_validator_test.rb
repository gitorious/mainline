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
#
#
require "fast_test_helper"
require "validators/ssh_key_validator"

class SshKeyValidatorTest < MiniTest::Spec
  def new_key(opts={})
    SshKey.new({
        :user_id => 1,
        :key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com"
    }.merge(opts))
  end

  it "validates presence of user_id and key" do
    result = SshKeyValidator.call(SshKey.new)
    refute result.valid?
    assert result.errors[:user_id]
    assert result.errors[:key]
  end

  it "validates the key using ssh-keygen" do
    validator = SshKeyValidator.new(new_key)
    validator.expects(:valid_key_using_ssh_keygen?).returns(false)
    refute validator.valid?
  end

  it "only allows unique ssh keys across the whole site" do
    key = new_key
    def key.uniq?; false; end
    refute SshKeyValidator.call(key).valid?
  end

  it "detects invalid ssh keys" do
    ssh_key = new_key(:key => "")
    validator = SshKeyValidator.new(ssh_key)
    validator.stubs(:valid_key_using_ssh_keygen?).returns(true)
    refute validator.valid?

    ssh_key.key = 'żółć'
    refute validator.valid?, 'is not valid when key format cannot be matched'

    ssh_key.key = "foo bar@baz"
    refute validator.valid?

    ssh_key.key = "ssh-somealgo as23d$%&asdasdasd bar@baz"
    refute validator.valid?

    ssh_key.key = "ssh-somealgo as23d$%&asdasdasd bar@baz"
    refute validator.valid?

    ssh_key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE foo@steakhouse.local"
    assert validator.valid?

    ssh_key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE foo@steak_house.local"
    assert validator.valid?
  end

  it "detects attempts at uploading private key" do
    ssh_key = new_key(:key => <<EOF)
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

    result = SshKeyValidator.call(ssh_key)
    refute result.valid?
    assert_match "private", result.errors[:key].join("")
  end

  it "allows a wider range of extended comments" do
    ssh_key = new_key(:key => "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE #{Gitorious.host} key")
    validator = SshKeyValidator.new(ssh_key)
    validator.stubs(:valid_key_using_ssh_keygen?).returns(true)
    assert validator.valid?

    ssh_key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE joe+#{Gitorious.host} key"
    assert validator.valid?

    ssh_key.key = "ssh-rsa AAAAB3Nz/aC1yc2EAAAABIwAAAQE #{Gitorious.scheme}://#{Gitorious.host} key"
    assert validator.valid?
  end

  it "ignores superfluous keys" do
    encoded_key = "bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU="
    k = "ssh-rsa #{encoded_key} foo@example.com"
    ssh_key = new_key(:key => "#{k}\r#{k}")
    validator = SshKeyValidator.new(ssh_key)
    validator.stubs(:valid_key_using_ssh_keygen?).returns(true)
    assert validator.valid?

    ssh_key = new_key(:key => "#{k}\n#{k}")
    assert validator.valid?
  end
end
