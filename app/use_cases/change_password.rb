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

class ChangePasswordCommand
  def initialize(user)
    @user = user
  end

  def execute(user)
    user.save!
    user
  end

  def build(params)
    @user.password = params.password
    @user.password_confirmation = params.password_confirmation
    @user
  end
end

class PasswordChangeParams
  include Virtus.model
  attribute :current_password, :String
  attribute :password, :String
  attribute :password_confirmation, :String
  attribute :actor, Object
end

class CurrentPasswordRequired
  def initialize(user)
    @user = user
  end

  def satisfied?(params)
    return true if @user.is_openid_only?
    User.authenticate(@user.email, params.current_password)
  end
end

class ChangePassword
  include UseCase

  def initialize(user)
    input_class(PasswordChangeParams)
    add_pre_condition(CurrentUserRequired.new(user))
    add_pre_condition(CurrentPasswordRequired.new(user))
    step(ChangePasswordCommand.new(user), :validator => PasswordValidator)
  end
end
