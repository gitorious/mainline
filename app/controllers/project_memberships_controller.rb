# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class ProjectMembershipsController < ApplicationController
  include ProjectFilters

  before_filter :require_private_repos
  before_filter :find_project
  before_filter :login_required
  before_filter :require_admin
  renders_in_site_specific_context :only => [:index]

  def index
    @memberships = paginate(page_free_redirect_options) do
      @project.project_memberships.paginate(:all, :page => params[:page])
    end

    @root = Breadcrumb::ProjectMemberships.new(@project)
  end

  def create
    membership = @project.project_memberships.new
    membership.member = member(params[:user], params[:group])
    membership.save
    redirect_to :action => "index"
  rescue ActiveRecord::RecordNotFound => err
    index
    m = err.message.match(/([^\s]+) with [^\s]+ = (.*)/)
    flash[:error] = "No such #{m[1].downcase} '#{m[2]}'"
    render :action => "index"
  end

  def destroy
    @project.project_memberships.find(params[:id]).destroy
    redirect_to :action => "index"
  end

  private
  def require_private_repos
    if !GitoriousConfig["enable_private_repositories"]
      redirect_to :controller => "projects", :action => "show", :id => params[:project_id]
    end
  end

  def member(user, group)
    return User.find_by_login!(user[:login]) if user
    return Group.find_by_name!(group[:name]) if group
    @project.owner
  end
end
