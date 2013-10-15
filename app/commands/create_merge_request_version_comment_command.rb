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
require "create_commit_comment_command"
require "create_merge_request_comment_command"

class CreateMergeRequestVersionCommentCommand < CreateMergeRequestCommentCommand
  def initialize(user, merge_request_version, commit_range = nil)
    @commit_range = commit_range
    super(user, merge_request_version)
  end

  def execute(comment)
    comment.save
    create_event(comment)
    owner = target.merge_request.user
    notify_repository_owner(comment, owner) if owner != comment.user
    add_to_favorites(comment.target.merge_request, comment.user) if add_to_favorites?
    comment
  end

  def build(params)
    self.add_to_favorites = params.add_to_favorites
    CreateCommitCommentCommand.new(user, target, commit_range).build(params)
  end

  protected
  attr_reader :commit_range
end

class MergeRequestVersionCommentParams < CommentParams
  attribute :add_to_favorites, Boolean
  attribute :context, String
  attribute :lines, String
  attribute :path, String
end
