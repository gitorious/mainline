# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
  before_filter :comment_should_be_editable, :only => [:edit, :update]
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

  def new
    render_form(target.comments.new)
  end

  def create
    uc = create_use_case
    outcome = uc.execute(params[:comment].merge(:add_to_favorites => params[:add_to_favorites]))

    pre_condition_failed(outcome) do |pc|
      flash[:error] = "Couldn't create comment: #{pc.pre_condition.message}"
      redirect_to(create_failed_path)
    end

    outcome.success do |comment|
      flash[:success] = "Your comment was added"
      redirect_to(create_succeeded_path(comment))
    end

    outcome.failure { |comment| render_form(comment) }
  end

  def edit
    render_form(@comment)
  end

  def update
    outcome = UpdateComment.new(@comment, current_user).execute(params[:comment])

    pre_condition_failed(outcome) do |pc|
      flash[:error] = "Couldn't update comment: #{pc.pre_condition.message}"
      redirect_to(update_failed_path)
    end

    outcome.success do |comment|
      flash[:success] = "Your comment was updated"
      redirect_to(update_succeeded_path(comment))
    end

    outcome.failure { |comment| render_form(comment) }
  end

  protected
  helper_method :update_comment_path
  helper_method :edit_comment_path

  def create_failed_path
    # Implement in sub-classes
  end

  def create_succeeded_path(comment)
    # Implement in sub-classes
  end

  def update_failed_path
    # Implement in sub-classes
  end

  def update_succeeded_path(comment)
    # Implement in sub-classes
  end

  def render_form(comment)
    render(:action => "edit", :locals => {
        :user => current_user,
        :repository => RepositoryPresenter.new(@repository),
        :comment => comment
      })
  end

  def find_repository
    rid = params[:repository_id]
    @repository = @owner.repositories.find_by_name_in_project!(rid, @containing_project)
  end

  def comment_should_be_editable
    @comment = authorize_access_to(find_comment)
    if !can_edit?(current_user, @comment)
      flash[:error] = !@comment.recently_created? ? "Only recently created comments can be edited, sorry" :  "You are not authorized to edit this comment"
      redirect_to(update_failed_path)
    end
  end

  def find_comment
    Comment.find(params[:id])
  end
end
