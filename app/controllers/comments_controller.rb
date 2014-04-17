# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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
require "gitorious/view/avatar_helper"

class CommentsController < ApplicationController
  include Gitorious::View::AvatarHelper
  before_filter :login_required, :except => [:index]
  before_filter :find_project_and_repository
  before_filter :comment_should_be_editable, only: [:update]
  renders_in_site_specific_context

  def index
    locals = {
      :repository => RepositoryPresenter.new(@repository),
      :project => @project,
      :comments => target.comments.includes(:user)
    }

    respond_to do |format|
      format.html do
        render("index", :locals => locals.merge({
              :atom_auto_discovery_url => project_repository_comments_path(
                @project,
                @repository,
                :format => :atom
                )
            }))
      end
      format.atom { render("index", :locals => locals) }
    end
  end

  def create
    uc = create_use_case
    outcome = uc.execute(params[:comment].merge(:add_to_favorites => params[:add_to_favorites]))

    pre_condition_failed(outcome) do |pc|
      format.json do
        render nothing: true, status: :bad_request
      end
    end

    outcome.success do |comment|
      respond_to do |format|
        format.json do
          render json: CommitCommentJSONPresenter.new(self, comment).render_for(current_user)
        end
      end
    end

    outcome.failure do |comment|
      respond_to do |format|
        format.json do
          render json: comment.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    outcome = UpdateComment.new(@comment, current_user).execute(params[:comment])

    pre_condition_failed(outcome) do |pc|
      respond_to do |format|
        format.json do
          render nothing: true, status: :bad_request
        end
      end
    end

    outcome.success do |comment|
      respond_to do |format|
        format.json do
          render json: CommitCommentJSONPresenter.new(self, comment).render_for(current_user)
        end
      end
    end

    outcome.failure do |comment|
      respond_to do |format|
        format.json do
          render json: comment.errors, status: :unprocessable_entity
        end
      end
    end
  end

  protected
  helper_method :update_comment_path

  def find_repository
    rid = params[:repository_id]
    @repository = @owner.repositories.find_by_name_in_project!(rid, @containing_project)
  end

  def comment_should_be_editable
    @comment = authorize_access_to(find_comment)
    if !can_edit?(current_user, @comment)
      error_message = !@comment.recently_created? ? "Only recently created comments can be edited, sorry" : "You are not authorized to edit this comment"
      respond_to do |format|
        format.json do
          render json: { error: error_message }, status: :forbidden
        end
      end
    end
  end

  def find_comment
    Comment.find(params[:id])
  end
end
