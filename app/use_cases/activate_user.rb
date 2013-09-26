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
require "validators/nil_validator"
require "commands/activate_user_command"

class UserActivationParams
  include Virtus.model
  attribute :code, String
end

class ActivateUser
  include UseCase

  def initialize
    input_class(UserActivationParams)
    step(ActivateUserCommand.new(User), :validator => NilValidator.new("Invalid activation code"))
  end
end
