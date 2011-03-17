# encoding: utf-8
#--
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

class CommentsController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :find_project_and_repository
  before_filter :find_polymorphic_parent
  before_filter :comment_should_be_editable, :only => [:edit, :update]
  renders_in_site_specific_context

  def index
    @comments = @target.comments.find(:all, :include => :user)
    @merge_request_count = @repository.merge_requests.count_open
    @atom_auto_discovery_url = project_repository_comments_path(@project, @repository,
      :format => :atom)
    respond_to do |format|
      format.html { }
      format.atom { }
    end
  end
  
  def preview
    @comment = Comment.new(params[:comment])
    respond_to do |wants|
      wants.js
    end
  end
  
  def new
    @comment = @target.comments.new
  end
  
  def create
    state = params[:comment].delete(:state)
    @comment = @target.comments.new(params[:comment])
    @comment.user = current_user
    @comment.state = state
    @comment.project = @project
    render_or_redirect
  end

  def edit
    render :partial => "edit_body"
  end

  def update
    @comment.body = params[:comment][:body]
    @comment.save
    render :partial => @comment
  end
  
  protected
  def render_or_redirect
    if @comment.save
      comment_was_created
    else
      comment_was_invalid
    end
  end

  def comment_was_created
    create_new_commented_posted_event
    add_to_favorites if params[:add_to_favorites]
    respond_to do |wants|
      wants.html do
        flash[:success] = I18n.t "comments_controller.create_success"
        if @comment.sha1.blank?
          redirect_to_repository_or_target
        else
          redirect_to repo_owner_path(@repository,
            :project_repository_commit_path, @project, @repository, @comment.sha1)
        end
      end
      wants.js do
        case @target
        when Repository
          commit = @target.git.commit(@comment.sha1)
          @comments = @target.comments.find_all_by_sha1(@comment.sha1, :include => :user)
          @diffs = commit.parents.empty? ? [] : commit.diffs.select { |diff|
            diff.a_path == @comment.path
          }
          @file_diff = render_to_string(:partial => "commits/diffs")
        else
          @diffs = @target.diffs(range_or_string(@comment.sha1)).select{|d|
            d.a_path == @comment.path
          }
          @file_diff = render_to_string(:partial => "merge_request_versions/comments")
        end
        render :json => {
          "file-diff" => @file_diff,
          "comment" => render_to_string(:partial => @comment)
        }, :status => :created
      end
    end
  end

  def add_to_favorites
    favorite_target.watched_by!(current_user)
  end

  def favorite_target
    @target.is_a?(MergeRequest) ? @target : @target.merge_request
  end
  
  def comment_was_invalid
    respond_to { |wants|
      wants.html { render :action => "new" }
      wants.js   { render :nothing => true, :status => :not_acceptable }
    }
  end
  
  def applies_to_merge_request_version?
    MergeRequestVersion === @target
  end

  def range_or_string(str)
    if match = /^([a-z0-9]*)-([a-z0-9]*)$/.match(str)
      @sha_range = Range.new(match[1],match[2])
    else
      @sha_range = str
    end
  end

  def find_repository
    @repository = @owner.repositories.find_by_name_in_project!(params[:repository_id],
      @containing_project)
  end

  def find_polymorphic_parent
    if params[:merge_request_version_id]
      @target = MergeRequestVersion.find(params[:merge_request_version_id])
    elsif params[:merge_request_id]
      @target = @repository.merge_requests.find_by_sequence_number!(params[:merge_request_id])
    else
      @target = @repository
    end
  end

  def redirect_to_repository_or_target
    if @target == @repository
      redirect_to repo_owner_path(@repository, [@project, @target, :comments])
    else
      redirect_to repo_owner_path(@repository, [@project, @repository, @target])
    end
  end

  def create_new_commented_posted_event
    if applies_to_merge_request_version?
      @project.create_event(Action::COMMENT, @target.merge_request, current_user,
        @comment.to_param, "MergeRequest")
      return
    end

    if @target == @repository
      @project.create_event(Action::COMMENT, @repository, current_user,
        @comment.to_param, "Repository")
    else
      @project.create_event(Action::COMMENT, @target, current_user,
        @comment.to_param, "MergeRequest") if @comment.state_change.blank?
    end
  end

  def comment_should_be_editable
    @comment = Comment.find(params[:id])
    if !@comment.editable_by?(current_user)
      render :status => :unauthorized, :text => "Sorry mate"
    end
  end
end
