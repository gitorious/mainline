# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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
require "validators/password_validator"

# TODO: Ideally split this in a base user validator, a DB user
# validator and an OpenID user validator
UserValidator = UseCase::Validator.define do
  USERNAME_FORMAT = /^[a-z0-9\-_\.]*$/i.freeze

  validates_presence_of :login
  validates_format_of :login, :with => /^#{USERNAME_FORMAT}$/i
  validates_length_of :login, :within => 1..40, :allow_blank => true
  validates_format_of :email, :with => EmailValidator::EMAIL_FORMAT
  validates_presence_of :password, :if => :password_required?
  validates_length_of :password, :minimum => PASSWORD_MIN_LENGTH, :if => :password_required?
  validate :valid_password_confirmation, :if => :password_required?
  validates_length_of :email, :within => 5..100
  validates_format_of :avatar_file_name, :with => /\.(jpe?g|gif|png|bmp|svg|ico)$/i, :allow_blank => true
  validate :normalized_openid_identifier
  validate :uniqueness
  validate :avatar_is_valid

  # Helps validations not raise errors on Ruby 1.8.7
  def self.model_name
    ActiveModel::Name.new(self, nil, "User")
  end

  # For unknown reasons,
  # validates_confirmation_of :password, :if => :password_required?
  # did not work. If you are able to express this validation with the
  # validates_confirmation_of validator, please change this.
  def valid_password_confirmation
    errors.add(:password, "should match confirmation") if password != password_confirmation
  end

  def uniqueness
    errors.add(:login, "is already taken") if !uniq_login?
    errors.add(:email, "is already taken") if !uniq_email?
  end

  def normalized_openid_identifier
    return if !openid?
    begin
      normalize_identity_url(identity_url)
    rescue
      errors.add(:identity_url, I18n.t("user.invalid_url"))
    end
  end

  def avatar_is_valid
    errors.add(:avatar, I18n.t("user.avatar_invalid")) if avatar_has_processing_errors?
  end

  protected

  def password_required?
    !openid? && (crypted_password.blank? || !password.blank?)
  end

  def openid?
    !identity_url.blank?
  end

  def avatar_has_processing_errors?
    avatar.send(:flush_errors).present?
  end
end
