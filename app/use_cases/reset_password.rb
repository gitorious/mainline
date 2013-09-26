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
require "validators/new_password_validator"
require "virtus"

class ResetPasswordParams
  include Virtus.model
  attribute :password, String
  attribute :password_confirmation, String
end

class ResetPasswordCommand
  def initialize(user); @user = user; end
  def execute(user); user.save!; end

  def build(params)
    @user.password = params.password
    @user.password_confirmation = params.password_confirmation
    @user
  end
end

class ResetPassword
  include UseCase

  def initialize(user)
    input_class(ResetPasswordParams)
    add_pre_condition(RequiredDependency.new(:user, user))
    step(ResetPasswordCommand.new(user), :validator => NewPasswordValidator)
  end
end
