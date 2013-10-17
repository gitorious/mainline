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

module CommentValidators
  Basic = UseCase::Validator.define do
    validates_presence_of :user_id, :target, :project_id
  end

  class Editable < Basic
    validates_presence_of :body
  end

  class Commit < Editable
    validates_presence_of :sha1
    validates_format_of :sha1, :with => /^[a-z0-9]{40}$/
  end

  class MergeRequest < Basic
    validates_presence_of :body, :if =>  Proc.new { |mr| mr.state_change.blank? }
    validate :state_change_user

    def state_change_user
      return if state.blank? || Gitorious::App.can_resolve_merge_request?(user, target)
      errors.add(:state, "can only be updated by merge request owner")
    end
  end

  class MergeRequestVersion < Editable
    validates_format_of :sha1, :with => /^([a-z0-9]{40}(-[a-z0-9]{40})?)?$/
  end
end
