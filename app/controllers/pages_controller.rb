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
  before_filter :assert_readyness
  
  def index
    @tree_nodes = @project.wiki_repository.git.tree.contents.select{|n|
      n.name =~ /\.#{Page::DEFAULT_FORMAT}$/
    }
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
      flash[:error] = I18n.t("pages_controller.no_changes")
      render :action => "edit" and return
    end

    @page.content = params[:page][:content]
    if @page.save
      @project.create_event(Action::UPDATE_WIKI_PAGE, @project, current_user, @page.title)
      redirect_to project_page_path(@project, @page)
    else
      flash[:error] = I18n.t("pages_controller.invalid_page_error")
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
  
  protected
    def assert_readyness
      unless @project.wiki_repository.ready?
        flash[:notice] = I18n.t("pages_controller.repository_not_ready")
        redirect_to project_path(@project) and return
      end
    end
end
