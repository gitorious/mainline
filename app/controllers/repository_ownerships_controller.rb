# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class RepositoryOwnershipsController < ApplicationController
  before_filter :login_required
  before_filter :load_authorized_repository
  renders_in_site_specific_context

  def update
    groups = Team.for_user(current_user)
    owner_id = params[:repository][:owner_id]
    if owner_id.present?
      new_owner = groups.detect { |group| group.id == owner_id.to_i }
      @repository.change_owner_to!(new_owner)
      flash[:success] = "Repository ownership transferred"
      redirect_to [@repository.project, @repository]
    else
      render_form(@repository, groups)
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    render_form(@repository, groups)
  end

  def edit
    render_form(@repository, Team.for_user(current_user))
  end

  private
  def render_form(repository, groups)
    render(:action => :edit, :locals => {
        :repository => RepositoryPresenter.new(repository),
        :groups => groups
      })
  end

  def load_authorized_repository
    pid = params[:project_id]
    rid = params[:id]
    project = authorize_access_to(Project.find_by_slug!(pid))
    repository = authorize_access_to(project.repositories.find_by_name!(rid))
    unless admin?(current_user, repository)
      flash[:error] = I18n.t("repositories_controller.adminship_error")
      target = project_repository_path(project, repository)
      redirect_to(target) and return
    end
    @repository = repository
  end
end
