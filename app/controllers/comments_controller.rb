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
  renders_in_site_specific_context
  
  def index
    @comments = @repository.comments.find(:all, :include => :user)
    @merge_request_count = @repository.merge_requests.count_open
    @atom_auto_discovery_url = project_repository_comments_path(@project, @repository, :format => :atom)
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

    respond_to do |format|
      if @comment.save
        create_new_commented_posted_event
        format.html do
          flash[:success] = I18n.t "comments_controller.create_success"
          if @comment.sha1.blank?
            redirect_to_repository_or_target
          elsif MergeRequestVersion === @target
            render :nothing => true, :status => :created
          else
            redirect_to repo_owner_path(@repository, :project_repository_commit_path, @project, @repository, @comment.sha1)
          end
        end
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  protected
    def find_repository
      @repository = @owner.repositories.find_by_name_in_project!(params[:repository_id], @containing_project)
    end
    
    def find_polymorphic_parent
      if params[:merge_request_id]
        @target = @repository.merge_requests.find(params[:merge_request_id])
      elsif params[:merge_request_version_id]
        @target = MergeRequestVersion.find(params[:merge_request_version_id])
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
      # def create_event(action_id, target, user, data = nil, body = nil, date = Time.now.utc)
      if @target == @repository
        @project.create_event(Action::COMMENT, @repository, current_user, @comment.to_param, "Repository")
      else
        @project.create_event(Action::COMMENT, @target, current_user, @comment.to_param, "MergeRequest") if @comment.state_change.blank?
      end
    end
end
