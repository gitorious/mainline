#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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

class PagesController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_project
  
  def index
    redirect_to project_page_path(@project, "Home")
  end
  
  def show
    @page = Page.find(params[:id], @project.wiki_repository.git)
    if @page.new?
      redirect_to edit_project_page_path(@project, params[:id]) and return
    end
  end
  
  def edit
    @page = Page.find(params[:id], @project.wiki_repository.git)
    @page.user = current_user
  end
  
  def update
    @page = Page.find(params[:id], @project.wiki_repository.git)
    @page.user = current_user
    
    if @page.content == params[:page][:content]
      render :action => "edit" and return
    end

    @page.content = params[:page][:content]
    if @page.save
      redirect_to project_page_path(@project, @page)
    else
      render :action => "edit"
    end
  end
  
  def history
    @page = Page.find(params[:id], @project.wiki_repository.git)    
    if @page.new?
      redirect_to edit_project_page_path(@project, @page) and return
    end
    
    @commits = @page.history(30)
  end
end
