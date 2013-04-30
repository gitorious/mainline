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
require "validators/email_validator"

# TODO: Ideally split this in a base user validator, a DB user
# validator and an OpenID user validator
UserValidator = UseCase::Validator.define do
  USERNAME_FORMAT = /^[a-z0-9\-_\.]*$/i.freeze
  validates_presence_of :login, :if => :password_required?
  validates_format_of :login, :with => /^#{USERNAME_FORMAT}$/i
  validates_length_of :login, :within => 1..40, :allow_blank => true
  validates_format_of :email, :with => EmailValidator::EMAIL_FORMAT
  validates_presence_of :password, :if => :password_required?
  validates_length_of :password, :minimum => 4, :if => :password_required?
  validate :valid_password_confirmation, :if => :password_required?
  validates_length_of :email, :within => 5..100
  validates_format_of :avatar_file_name, :with => /\.(jpe?g|gif|png|bmp|svg|ico)$/i, :allow_blank => true
  validate :normalized_openid_identifier
  validate :unique_login

  # For unknown reasons,
  # validates_confirmation_of :password, :if => :password_required?
  # did not work. If you are able to express this validation with the
  # validates_confirmation_of validator, please change this.
  def valid_password_confirmation
    errors.add(:password, "should match confirmation") if password != password_confirmation
  end

  def unique_login
    errors.add(:login, "is already taken") if !uniq_login?
  end

  def normalized_openid_identifier
    return if !openid?
    begin
      normalize_url(identity_url)
    rescue
      errors.add(:identity_url, I18n.t("user.invalid_url"))
    end
  end

  protected
  def password_required?
    !openid? && (crypted_password.blank? || !password.blank?)
  end

  def openid?
    !identity_url.blank?
  end
end
