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
require "commands/create_comment_command"

class CreateCommitCommentCommand < CreateCommentCommand
  def initialize(user, repository, commit_id)
    @commit_id = commit_id
    super(user, repository)
  end

  def build(params)
    comment = super(params)
    comment.sha1 = commit_id
    comment.context = params.context
    comment.path = params.path
    comment.lines = params.lines unless params.lines.blank?
    comment
  end

  private
  attr_reader :commit_id
end

class CommitCommentParams < CommentParams
  attribute :context, String
  attribute :lines, String
  attribute :path, String
end
