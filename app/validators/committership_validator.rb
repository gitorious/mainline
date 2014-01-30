# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

CommittershipValidator = UseCase::Validator.define do
  validates_presence_of :committer_id, :committer_type, :repository_id, unless: :super_group?
  validate :uniqueness, unless: :super_group?

  def uniqueness
    errors.add(:committer_id, 'is already a committer') if !uniq?
  end

  def super_group?
    Gitorious::Configuration.get("enable_super_group") && SuperGroup.id == id
  end
end
