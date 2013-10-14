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
require "virtus"

class CreateCommentCommand
  def initialize(user, target)
    @user = user
    @target = target
  end

  def execute(comment)
    comment.save
    create_event(comment)
    comment
  end

  def build(params)
    Comment.new({
        :user => user,
        :target => target,
        :project => project,
        :body => params.body
      })
  end

  protected
  def create_event(comment)
    target = comment.target
    event_target = target.is_a?(MergeRequestVersion) ? target.merge_request : target
    project.create_event(Action::COMMENT, event_target, user, comment.to_param, event_target.class.to_s)
  end

  def project
    return target.project if target.respond_to?(:project)
    target.merge_request.project # MergeRequestVersion
  end

  attr_reader :user, :target
end

class CommentParams
  include Virtus.model
  attribute :body, String
end
