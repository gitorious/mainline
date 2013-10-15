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
require "create_commit_comment"

class RepositoryCommentsController < CommentsController
  def update_comment_path(comment)
    project_repository_comment_path(comment.project, comment.repository, comment)
  end

  def edit_comment_path(comment)
    edit_project_repository_comment_path(comment.project, comment.repository, comment)
  end

  protected
  # Callbacks from CommentController
  def target
    authorize_access_to(@repository)
  end

  def update_failed_path
    project_repository_comments_path(@project, @repository)
  end

  def update_succeeded_path
    project_repository_comments_path(@project, @repository)
  end
end
