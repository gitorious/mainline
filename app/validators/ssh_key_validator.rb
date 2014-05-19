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
require "tempfile"

SshKeyValidator = UseCase::Validator.define do
  KEY_FORMAT = /^ssh\-[a-z0-9]{3,4} [a-z0-9\+=\/]+ .*$/ims.freeze
  PRIVATE_KEY_FORMAT = /^-+.*PRIVATE.*-+$/ims.freeze

  validate :valid_ssh_key
  validates_presence_of :user_id, :key

  def self.model_name
    SshKey.model_name
  end

  def valid_ssh_key
    if key =~ PRIVATE_KEY_FORMAT
      errors.add(:key, I18n.t("ssh_key.private_key_validation_message")) and return
    end

    if key !~ KEY_FORMAT
      invalid_format! and return
    end

    if !uniq?
      errors.add(:key, I18n.t("ssh_key.unique_key_validation_message")) and return
    end

    # Only perform expensive check if otherwise valid
    if errors.count == 0 && !valid_key_using_ssh_keygen?
      errors.add(:key, "is not recognized as a valid public key")
    end
  rescue Encoding::CompatibilityError
    invalid_format! and return
  end

  def valid_key_using_ssh_keygen?
    temp_key = Tempfile.new("ssh_key_#{Time.now.to_i}")
    temp_key.write(self.key)
    temp_key.close
    system("ssh-keygen -l -f #{temp_key.path} > /dev/null")
    temp_key.delete
    return $?.success?
  end

  def invalid_format!
    errors.add(:key, I18n.t("ssh_key.key_format_validation_message"))
  end
end
