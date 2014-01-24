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

class RepositoryMembershipsController < ContentMembershipsController
  include RepositoryFilters
  include RepositoryMembershipsUtils
  before_filter :find_project_and_repository
  before_filter :find_repository_owner
  before_filter :require_admin

  protected
  def create_error(membership)
    committerships = CommittershipPresenter.collection(@repository.committerships.all, view_context)
    render("committerships/index", :locals => {
        :repository => RepositoryPresenter.new(@repository),
        :committerships => committerships,
        :committership => @repository.committerships.new_committership,
        :memberships => @repository.content_memberships,
        :membership => membership
      })
  end

  def redirect_options
    { :controller => "committerships", :action => "index" }
  end

  def require_private_repos
    if !Gitorious.private_repositories?
      find_project_and_repository if @repository.nil?
      redirect_to project_repository_path(@repository.project, @repository)
    end
  end
end
