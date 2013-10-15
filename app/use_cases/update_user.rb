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
require "validators/user_validator"

class UpdateUserCommand
  def initialize(user)
    @user = user
  end

  def execute(user)
    expire_avatar_email_caches(user)
    user.save!
    user
  end

  def build(params)
    @user.attributes = params.to_hash
    @user
  end

  private
  def expire_avatar_email_caches(user)
    return unless user.avatar_updated_at_changed?
    user.expire_avatar_email_caches
  end
end

class UpdateUserParams
  include Virtus.model
  attribute :fullname, String
  attribute :email, String
  attribute :url, String
  attribute :identity_url, String
  attribute :avatar, Object
  attribute :public_email, Boolean
  attribute :wants_email_notifications, Boolean
  attribute :default_favorite_notifications, Boolean

  def to_hash
    super.reject { |k,v| v.nil? }
  end
end

class UpdateUser
  include UseCase

  def initialize(user)
    add_pre_condition(RequiredDependency.new(:user, user))
    input_class(UpdateUserParams)
    step(UpdateUserCommand.new(user), :validator => UserValidator)
  end
end
