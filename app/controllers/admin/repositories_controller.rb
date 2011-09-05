# encoding: utf-8
#--
#   Copyright (C) 2010 Marius Mathiesen <marius@shortcut.no>
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
class Admin::RepositoriesController < ApplicationController
  before_filter :login_required
  before_filter :require_site_admin

  def index
    @unready_repositories = paginate(:action => "index") do
      Repository.regular.paginate(:all,:conditions => {:ready => false}, :per_page => 10, :page => params[:page])
    end
  end

  def recreate
    @repository = Repository.find(params[:id])
    @repository.post_repo_creation_message
    flash[:notice] = "Recreation message posted"
    redirect_to :action => :index
  end

  private
  def require_site_admin
    unless current_user.site_admin?
      flash[:error] = I18n.t "admin.users_controller.check_admin"
      redirect_to root_path
    end
  end
end
