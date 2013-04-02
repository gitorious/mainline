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
require "use_case"
require "virtus"

class DestroySshKeyCommand
  def initialize(hub)
    @hub = hub
  end

  def execute(ssh_key)
    @hub.publish("/queue/GitoriousDestroySshKey", :key => SshKeyFile.format(ssh_key))
    ssh_key.destroy
  end

  def build(params)
    params.ssh_key
  end
end

class DestroySshKeyParams
  include Virtus
  attribute :ssh_key, SshKey
  attribute :ssh_key_id, Integer
  def ssh_key; @ssh_key ||= SshKey.find(@ssh_key_id); end
end

class DestroySshKey
  include UseCase

  def initialize(app)
    input_class(DestroySshKeyParams)
    cmd = DestroySshKeyCommand.new(app)
    builder(cmd)
    validator(SshKeyValidator)
    command(cmd)
  end
end
