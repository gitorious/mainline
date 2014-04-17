# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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
require "create_merge_request_version_comment"

class MergeRequestVersionCommentsController < CommentsController
  include ParamsModelResolver

  def index
    respond_to do |format|
      format.json do
        comments = merge_request_version.comments_for_sha(params[:commit_range])
        render :json => CommitCommentsJSONPresenter.new(self, comments).render_for(current_user)
      end
    end
  end

  def update_comment_path(comment)
    project_repository_merge_request_version_update_comment_path(project, repository, merge_request, merge_request_version, comment.id)
  end

  protected
  # Callbacks from CommentController
  def target
    merge_request_version
  end

  def create_use_case
    CreateMergeRequestVersionComment.new(current_user, target, params[:commit_range])
  end

end
