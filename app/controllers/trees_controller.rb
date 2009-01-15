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

class TreesController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  
  def index
    redirect_to(project_repository_tree_path(@project, @repository, 
        @repository.head_candidate_name, []))
  end
  
  def show
    @git = @repository.git
    @commit = @git.commit(params[:id])
    unless @commit
      redirect_to project_repository_tree_path(@project, @repository, "HEAD", params[:path])
      return
    end
    path = params[:path].blank? ? [] : ["#{params[:path].join("/")}/"] # FIXME: meh, this sux
    @tree = @git.tree(@commit.tree.id, path)
  end
  
  def archive
    @git = @repository.git    
    @commit = @git.commit(params[:id])
    
    if @commit
      prefix = "#{@project.slug}-#{@repository.name}"
      data = @git.archive_tar_gz(params[:id], prefix + "/")      
      send_data(data, :type => 'application/x-gzip', 
        :filename => "#{prefix}.tar.gz") 
    else
      flash[:error] = I18n.t "trees_controller.archive_error"
      redirect_to project_repository_path(@project, @repository) and return
    end
  end
end
