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
require "makeup/markup"

class CommitCommentJSONPresenter

  attr_reader :app, :comment

  def initialize(app, comment)
    @app = app
    @comment = comment
  end

  def render_for(user)
    JSON.dump(hash_for(user))
  end

  def hash_for(user)
    repository = comment.target
    project = repository.project

    {
      "id" => comment.id,
      "author" => {
        "profilePath" => app.user_path(comment.user),
        "avatarUrl" => app.avatar_url(comment.user),
        "login" => comment.user.login,
        "name" => comment.user.fullname
      },
      "body" => comment.body,
      "bodyHtml" => Makeup::Markup.new.render("text.md", comment.body).strip,
      "createdAt" => comment.created_at.iso8601,
      "updatedAt" => comment.updated_at.iso8601,
      "firstLine" => comment.first_line_number,
      "lastLine" => comment.last_line_number,
      "context" => comment.context,
      "path" => comment.path,
      "sha1" => comment.sha1,
      "htmlUrl" => html_url,
      "statusChangedFrom" => comment.state_changed_from,
      "statusChangedTo" => comment.state_changed_to,
      "statusChangedFromIsOpen" => MergeRequestStatus.open?(comment.state_changed_from),
      "statusChangedToIsOpen" => MergeRequestStatus.open?(comment.state_changed_to),
    }.merge(!app.can_edit?(user, comment) ? {} : {
      "updateUrl" => app.update_comment_path(comment),
      "editableUntil" => comment.editable_until.iso8601
    })
  end

  private

  def html_url
    return unless comment.applies_to_line_numbers?
    app.project_repository_commit_path(comment.project, comment.repository, comment.sha1)
  end

end
