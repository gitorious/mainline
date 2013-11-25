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

PasswordValidator = UseCase::Validator.define do
  PASSWORD_MIN_LENGTH = 4

  validates_presence_of :password
  validate :valid_password_confirmation
  validates_length_of :password, :minimum => PASSWORD_MIN_LENGTH

  # For unknown reasons, `validates_confirmation_of :password` does
  # not work. If you are able to express this validation with the
  # validates_confirmation_of validator, please change this.
  def valid_password_confirmation
    errors.add(:password, "should match confirmation") if password != password_confirmation
  end
end
