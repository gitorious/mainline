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
require "create_comment_command"

class CreateMergeRequestCommentCommand < CreateCommentCommand
  def initialize(user, merge_request)
    super(user, merge_request)
  end

  def execute(comment)
    comment.save
    create_event(comment) if !comment.body.blank?
    notify_repository_owner(comment, comment.target.user) if target.user != user
    update_merge_request_state(comment) if !comment.state_change.blank?
    add_to_favorites(comment.target, user) if add_to_favorites?
    comment
  end

  def build(params)
    comment = super
    comment.state = params.state if params.respond_to?(:state)
    self.add_to_favorites = params.add_to_favorites
    comment
  end

  protected
  def add_to_favorites=(atf)
    @add_to_favorites = atf
  end

  def add_to_favorites?
    @add_to_favorites
  end

  def add_to_favorites(merge_request, user)
    merge_request.watched_by!(user)
  end

  def notify_repository_owner(comment, owner)
    message_body = "#{comment.user.title} commented:\n\n#{comment.body}"

    if comment.state_changed_to
      message_body << "\n\nThe status of your merge request"
      message_body << " is now #{comment.state_changed_to}"
    end

    SendMessage.call(
      :sender => comment.user,
      :recipient => owner,
      :subject => "#{user.title} commented on your merge request",
      :body => message_body,
      :notifiable => comment.target)
  end

  def update_merge_request_state(comment)
    comment.target.with_user(user) do
      comment.target.status_tag = comment.state_changed_to
      comment.target.create_status_change_event(comment.body)
    end
  end
end

class MergeRequestCommentParams < CommentParams
  attribute :state, String
  attribute :add_to_favorites, Boolean
end
