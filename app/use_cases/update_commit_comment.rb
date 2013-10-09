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
require "validators/comment_validator"

class UpdateCommitCommentCommand
  def initialize(comment)
    @comment = comment
  end

  def execute(comment)
    comment.save
    comment
  end

  def build(params)
    comment.body = params.body
    comment
  end

  private
  attr_reader :comment
end

class UpdateCommitCommentParams
  include Virtus.model
  attribute :body, String
end

class UpdateCommitComment
  include UseCase

  def initialize(comment, user)
    add_pre_condition(CurrentUserRequired.new(user))
    add_pre_condition(OwnerRequired.new(comment, user))
    input_class(UpdateCommitCommentParams)
    step(UpdateCommitCommentCommand.new(comment), :validator => CommitCommentValidator)
  end
end
