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

class CreateUserCommand
  def execute(user)
    user.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by { rand }.join)
    user.save!
    Mailer.signup_notification(user).deliver if user.identity_url.blank?
    user.accept_terms!
    user
  end

  def build(params)
    User.new(params.to_hash)
  end
end

class NewUserParams
  include Virtus.model
  attribute :login, String
  attribute :fullname, String
  attribute :email, String
  attribute :password, String
  attribute :password_confirmation, String
  attribute :terms_of_use, Boolean
end

class CreateUser
  include UseCase

  def initialize
    input_class(NewUserParams)
    step(CreateUserCommand.new, :validator => NewUserValidator)
  end
end
