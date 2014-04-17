# encoding: utf-8
#--
#   Copyright (C) 2011-2014 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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
require "commit_comments_json_presenter"

class CommitCommentsController < CommentsController
  def index
    respond_to do |format|
      format.json do
        comments = @repository.commit_comments(params[:ref])
        render(:json => CommitCommentsJSONPresenter.new(self, comments).render_for(current_user))
      end
    end
  end

  def update_comment_path(comment)
    if comment.new_record?
      project_repository_create_commit_comment_path(@project, @repository, comment.sha1)
    else
      project_repository_update_commit_comment_path(@project, @repository, comment.sha1, comment.id)
    end
  end

  protected
  # Callbacks from CommentController
  def create_use_case
    CreateCommitComment.new(current_user, @repository, params[:ref])
  end

  def find_comment
    Comment.where({
        :id => params[:id],
        :sha1 => params[:ref],
        :target_type => "repository",
        :target_id => @repository.id
      }).first
  end
end
