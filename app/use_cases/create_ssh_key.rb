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
require "commands/create_ssh_key_command"

class CreateSshKey
  include UseCase

  def initialize(hub, user)
    user = User.find(user) if user.is_a?(Integer)
    input_class(NewSshKeyParams)
    add_pre_condition(RequiredDependency.new(:user, user))
    step(CreateSshKeyCommand.new(hub, user), :validator => SshKeyValidator)
  end
end
