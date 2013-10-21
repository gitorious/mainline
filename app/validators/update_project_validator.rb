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

UpdateProjectValidator = UseCase::Validator.define do
  validates_presence_of :default_merge_request_status
  validate :merge_request_statuses_valid

  def self.model_name
    Project.model_name
  end

  def to_param
    @target.slug
  end

  private

  def default_merge_request_status
    merge_request_statuses.reject(&:marked_for_destruction?).find(&:default)
  end

  def merge_request_statuses_valid
    if merge_request_statuses.any?(&:invalid?)
      errors.add(:merge_request_statuses, I18n.t('project.merge_request_statuses_invalid'))
    end
  end
end
