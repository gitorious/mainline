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

RepositoryValidator = UseCase::Validator.define do
  REPOSITORY_NAME_FORMAT = /[a-z0-9_\-]+/i.freeze
  validates_presence_of(:user_id, :name, :owner_id, :project_id)
  validates_exclusion_of(:name, :in => lambda { |r| Repository.reserved_names })
  validates_format_of(:name, {
      :with => /^#{REPOSITORY_NAME_FORMAT}$/i,
      :message => "is invalid, must match something like /[a-z0-9_\\-]+/"
    })
  validate :uniqueness

  def uniqueness
    message = proc { |attr| "repository.unique_#{attr}_validation_message" }
    errors.add(:key, I18n.t(message.call("name"))) if !uniq_name?
    errors.add(:key, I18n.t(message.call("hashed_path"))) if !uniq_hashed_path?
  end

  def self.model_name
    Repository.model_name
  end
end
