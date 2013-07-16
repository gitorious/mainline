# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "ssh_key_test_helper"

class SshKeyTest < ActiveSupport::TestCase
  include SshKeyTestHelper

  context ".ready" do
    should "return ssh keys that are ready" do
      ssh_keys(:johan).update_attribute(:ready, true)
      ssh_keys(:mike).update_attribute(:ready, true)

      assert_equal Set.new([ssh_keys(:johan), ssh_keys(:mike)]), Set.new(SshKey.ready)
    end
  end

  should "ignore superfluous keys" do
    encoded_key = "bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU="
    k = "ssh-rsa #{encoded_key} foo@example.com"
    ssh = new_key(:key => "#{k}\r#{k}")
    assert_equal "ssh-rsa", ssh.algorithm
    assert_equal encoded_key, ssh.encoded_key

    ssh = new_key(:key => "#{k}\n#{k}")
    assert_equal "ssh-rsa", ssh.algorithm
    assert_equal encoded_key, ssh.encoded_key
  end

  should "clean out newlines" do
    ssh_key = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\n9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")

    refute_match /\n/, ssh_key.key
  end

  should "strip newlines in key" do
    ssh = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\n9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")
    assert !ssh.key.include?("\n")

    ssh = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\r\n9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")
    assert !ssh.key.include?("\r\n")

    ssh = new_key(:key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG\r9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cm\nVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com")
    assert !ssh.key.include?("\r")
  end

  should "strip beginning and ending whitespace+newlines" do
    ssh = new_key(:key => "\n ssh-rsa asdfsomekey foo@example.com  \n  ")
    assert_equal "ssh-rsa asdfsomekey foo@example.com", ssh.key
  end

  should "wrap the key at 72 columns for display" do
    ssh = new_key
    expected_wrapped = <<EOS
ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dk
anB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216
ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com
EOS
    assert_equal expected_wrapped.strip, ssh.wrapped_key
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

  should "recognize unique key" do
    ssh_key = new_key
    assert ssh_key.uniq?

    ssh_key.save!
    assert ssh_key.uniq?
  end

  should "recognize non-unique key" do
    ssh_key = new_key
    ssh_key.save!
    ssh_key2 = new_key(:key => ssh_key.key)

    refute ssh_key2.uniq?
  end
end
