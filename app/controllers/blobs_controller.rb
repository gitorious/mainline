#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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

class BlobsController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  

  def show
    @git = @repository.git
    @commit = @git.commit(params[:id])
    unless @commit
      redirect_to project_repository_blob_path(@project, @repository, "HEAD", params[:path])
      return
    end
    @blob = @git.tree(@commit.tree.id, ["#{params[:path].join("/")}"]).contents.first
    @root = Breadcrumb::Blob.new(:paths => params[:path], :head => @git.head, :repository => @repository, :name => @blob.basename)
    render_not_found and return unless @blob
    unless @blob.respond_to?(:data) # it's a tree
      redirect_to project_repository_tree_path(@project, @repository, @commit.id, params[:path])
    end
  end

  def raw
    @git = @repository.git
    @commit = @git.commit(params[:id])
    unless @commit
      redirect_to project_repository_raw_blob_path(@project, @repository, "HEAD", params[:path])
      return
    end
    @blob = @git.tree(@commit.tree.id, ["#{params[:path].join("/")}"]).contents.first
    render_not_found and return unless @blob
    if @blob.size > 500.kilobytes
      flash[:error] = I18n.t "blogs_controller.raw_error"
      redirect_to project_repository_path(@project, @repository) and return
    end
    render :text => @blob.data, :content_type => @blob.mime_type
  end
  
  # def text
  # end
end
