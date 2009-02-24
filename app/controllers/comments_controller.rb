#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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
  
  def index
    @comments = @repository.comments.find(:all, :include => :user)
    @merge_request_count = @repository.merge_requests.count_open
    @atom_auto_discovery_url = project_repository_comments_path(@project, @repository, :format => :atom)
    respond_to do |format|
      format.html { }
      format.atom { }
    end
  end
  
  def new
    @comment = @repository.comments.new
  end
  
  def create
    @comment = @repository.comments.new(params[:comment])
    @comment.user = current_user
    @comment.project = @project
    @comment.target = @repository
    respond_to do |format|
      if @comment.save
        @project.create_event(Action::COMMENT, @comment, current_user)
        format.html do
          flash[:success] = I18n.t "comments_controller.create_success"
          if @comment.sha1.blank?
            redirect_to project_repository_comments_path(@project, @repository)
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
      @repository = @owner.repositories.find_by_name!(params[:repository_id])
    end
end
