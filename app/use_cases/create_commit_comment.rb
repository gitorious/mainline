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

class CreateCommitCommentCommand
  def initialize(user, repository, commit_id)
    @user = user
    @repository = repository
    @commit_id = commit_id
  end

  def execute(comment)
    comment.save
    comment
  end

  def build(params)
    comment = Comment.new({
        :user => user,
        :target => repository,
        :sha1 => commit_id,
        :project => repository.project,
        :body => params.body,
        :context => params.context,
        :path => params.path
      })
    comment.lines = params.lines unless params.lines.blank?
    comment
  end

  private
  attr_reader :user, :repository, :commit_id
end

class CommitCommentParams
  include Virtus.model
  attribute :body, String
  attribute :context, String
  attribute :lines, String
  attribute :path, String
end

class CreateCommitComment
  include UseCase

  def initialize(user, repository, commit_id)
    input_class(CommitCommentParams)
    step(CreateCommitCommentCommand.new(user, repository, commit_id), :validator => CommitCommentValidator)
  end
end
