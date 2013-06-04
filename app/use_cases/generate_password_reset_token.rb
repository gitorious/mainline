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

class GeneratePasswordResetTokenCommand
  def initialize(user)
    @user = user
  end

  def execute(user)
    user.password_key = self.class.generate_reset_key
    user.save!
    Mailer.forgotten_password(user, user.password_key).deliver
    user
  end

  def build(params)
    @user
  end

  def self.generate_reset_key(n = 16)
    SecureRandom.hex(n)
  end
end

GeneratePasswordResetTokenValidator = UseCase::Validator.define do
  validate :user_activated

  def user_activated
    return if activated?
    message = I18n.t("users_controller.reset_password_inactive_account")
    errors.add(:activated?, message)
  end
end

class GeneratePasswordResetToken
  include UseCase

  def initialize(user)
    add_pre_condition(RequiredDependency.new(:user, user))
    step(GeneratePasswordResetTokenCommand.new(user), :validator => GeneratePasswordResetTokenValidator)
  end
end
