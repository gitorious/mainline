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
require "create_merge_request_comment"

class MergeRequestCommentsController < CommentsController
  protected
  def edit_comment_path(comment)
    mr = comment.target
    edit_project_repository_merge_request_comment_path(mr.project, mr.target_repository, mr, comment)
  end

  def update_comment_path(comment)
    mr = comment.target
    project_repository_merge_request_comment_path(mr.project, mr.target_repository, mr, comment)
  end

  # Callbacks from CommentController
  def target
    id = params[:merge_request_id]
    @merge_request ||= authorize_access_to(@repository.merge_requests.public.find_by_sequence_number!(id, :include => [:source_repository, :target_repository]))
  end

  def create_use_case
    CreateMergeRequestComment.new(current_user, target)
  end

  def create_failed_path
    project_repository_merge_request_path(@project, @repository, target)
  end

  def create_succeeded_path(comment)
    project_repository_merge_request_path(@project, @repository, target)
  end

  def update_failed_path
    project_repository_merge_request_path(@project, @repository, target)
  end

  def update_succeeded_path(comment)
    project_repository_merge_request_path(@project, @repository, target)
  end
end
