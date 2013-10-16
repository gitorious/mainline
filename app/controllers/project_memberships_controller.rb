# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class ProjectMembershipsController < ContentMembershipsController
  include ProjectFilters
  before_filter :find_project
  before_filter :require_admin
  before_filter :require_private_repos

  def index
    render("index", :locals => {
        :memberships => content.content_memberships,
        :project => @project
      })
  end

  protected
  def create_error(membership)
    render("index", :locals => {
        :memberships => content.content_memberships,
        :project => @project,
        :membership => membership
      })
  end

  def require_private_repos
    if !Gitorious.private_repositories?
      find_project if @project.nil?
      redirect_to project_path(@project)
    end
  end

  def content
    @project
  end

  def memberships_path(content)
    project_project_memberships_path(content)
  end

  def membership_path(content, membership)
    project_project_membership_path(content, membership)
  end

  def new_membership_path(content)
    new_project_project_membership_path(content)
  end

  def content_path(content)
    project_path(content)
  end
end
