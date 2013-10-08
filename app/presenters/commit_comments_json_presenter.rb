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
require "makeup/markup"

class CommitCommentsJSONPresenter
  def initialize(app, comments)
    @app = app
    @comments = comments
  end

  def render_for(user)
    JSON.dump(hash_for(user))
  end

  def hash_for(user)
    { "commit" => commit_comments(comments, user),
      "diffs" => diff_comments(comments, user) }
  end

  protected
  def commit_comments(comments, user)
    comments.select { |c| c.path.nil? }.map { |c| comment_hash(c, user) }
  end

  def diff_comments(comments, user)
    comments = comments.select { |c| !c.path.nil? }.map { |c| comment_hash(c, user) }
    comments.group_by { |c| c["path"] }
  end

  def comment_hash(comment, user)
    repository = comment.target
    project = repository.project
    { "author" => {
        "profilePath" => app.user_path(comment.user),
        "avatarUrl" => app.avatar_url(comment.user),
        "login" => comment.user.login,
        "name" => comment.user.fullname
      },
      "body" => Makeup::Markup.new.render("text.md", comment.body),
      "createdAt" => comment.created_at.iso8601,
      "updatedAt" => comment.updated_at.iso8601,
      "firstLine" => comment.first_line_number,
      "lastLine" => comment.last_line_number,
      "context" => comment.context,
      "path" => comment.path }.merge(user != comment.user ? {} : {
        "updatePath" => app.project_repository_update_commit_comment_path(project, repository, comment.sha1, comment.id)
      })
  end

  attr_reader :app, :comments
end
