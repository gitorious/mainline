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

class CommitsController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  
  def index
    redirect_to project_repository_log_path(@project, @repository, @repository.head_candidate.name)
  end

  def show
    @diffmode = params[:diffmode] == "sidebyside" ? "sidebyside" : "inline"
    @git = @repository.git
    @commit = @git.commit(params[:id])
    @diffs = @commit.diffs
    @comment_count = @repository.comments.count(:all, :conditions => {:sha1 => @commit.id.to_s})
    respond_to do |format|
      format.html
      # TODO: format.diff { render :content_type => "text/plain" }
    end
  end
  
end
