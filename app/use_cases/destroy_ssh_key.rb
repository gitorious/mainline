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
  def initialize(hub, user)
    @hub = hub
    @user = user
  end

  def execute(ssh_key)
    @hub.publish("/queue/GitoriousDestroySshKey", :id => ssh_key.id)
    ssh_key.destroy
  end

  def build(params)
    @user.ssh_keys.find(params.id)
  end
end

class DestroySshKeyParams
  include Virtus
  attribute :id, Integer
end

class DestroySshKey
  include UseCase

  def initialize(app, user)
    input_class(DestroySshKeyParams)
    add_pre_condition(UserRequired.new(user))
    step(DestroySshKeyCommand.new(app, user), :validator => SshKeyValidator)
  end
end
