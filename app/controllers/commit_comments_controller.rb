# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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
require "gitorious/view/avatar_helper"

class CommitCommentsController < ApplicationController
  include Gitorious::View::AvatarHelper
  before_filter :login_required, :except => [:index]
  before_filter :find_project_and_repository
  layout "ui3"

  def index
    respond_to do |format|
      format.json do
        comments = @repository.commit_comments(params[:ref])
        render(:json => CommitCommentsJSONPresenter.new(self, comments).render_for(current_user))
      end
    end
  end

  def create
    uc = CreateCommitComment.new(current_user, @repository, params[:ref])
    outcome = uc.execute(params[:comment])

    pre_condition_failed(outcome) do |pc|
      flash[:error] = "Couldn't create comment: #{pc.pre_condition.message}"
      redirect_to(project_repository_commit_path(@project, @repository, params[:ref]))
    end

    outcome.success do |comment|
      flash[:success] = "Your comment was added"
      redirect_to(project_repository_commit_path(@project, @repository, comment.sha1))
    end

    outcome.failure { |comment| render_form(comment) }
  end

  def edit
    render_form(find_comment)
  end

  def update
    outcome = UpdateCommitComment.new(find_comment, current_user).execute(params[:comment])

    pre_condition_failed(outcome) do |pc|
      flash[:error] = "Couldn't update comment: #{pc.pre_condition.message}"
      redirect_to(project_repository_commit_path(@project, @repository, params[:ref]))
    end

    outcome.success do |comment|
      flash[:success] = "Your comment was updated"
      redirect_to(project_repository_commit_path(@project, @repository, comment.sha1))
    end

    outcome.failure { |comment| render_form(comment) }
  end

  private
  def find_comment
    Comment.where({
        :id => params[:id],
        :sha1 => params[:ref],
        :target_type => "repository",
        :target_id => @repository.id
      }).first
  end

  def render_form(comment)
    render(:action => "edit", :locals => {
        :user => current_user,
        :repository => RepositoryPresenter.new(@repository),
        :comment => comment
      })
  end
end
