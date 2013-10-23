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
require "test_helper"

module SshKeyTestHelper
  def new_key(opts={})
    SshKey.new({
        :user_id => 1,
        :key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU= foo@example.com",
      }.merge(opts))
  end

  def key_with_content(algo = nil, key = nil, comment = nil)
    algo ||= "ssh-rsa"
    key ||= "bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFzc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRiZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4Zm9mcWU="
    comment ||= "foo@bar.com"
    new_key({
        :key => "#{algo} #{key} #{comment}",
      })
  end

  def valid_key
    <<-EOS
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxQBUzS41JmQsaB5ZR2JRp/QYZGITLt+6CLiDM23cXY7IWM/LwfujNXJrxGciO1UiS27RaDtpIbMoW85gqRuxkR5wjU1tuEBb0MxQq2yfPG6UDuscsXdoJkwxAuvqgjBTFYkFKsL0USk/u3k1ocljd6guKxWzDeeNfF2HnbHIPB/ZgwFJ9PLdlfLeZFY76WYs8hYnQOLvhkoCxhax82xllz5Axn5p5Bh85dhg6RR7Qg3Fh9A5hmerPVgGnJuI2fKIt2a/vd9sjc7ptIuaocASMr1DOAT51zPnfD8cTpP+zzdfBBQ5iGSqmxO3tm60ayRZixuJkPvmnz5SjIvYPy67Uw== foo@example.com
EOS
  end

  def invalid_key
    "ooger booger wooger@burger"
  end
end
