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

class ProjectOwnershipsController < ApplicationController
  before_filter :login_required
  renders_in_site_specific_context

  def update
    uc = TransferProjectOwnership.new(self, project, current_user)
    outcome = uc.execute(params[:project])
    pre_condition_failed(outcome)
    outcome.failure { |project| render_form(project, Team.by_admin(current_user)) }
    outcome.success do |project|
      flash[:success] = "Project ownership transferred"
      redirect_to(project_path(project))
    end
  end

  def edit
    project = load_authorized_project
    return if project.nil?
    render_form(project, Team.by_admin(current_user))
  end

  private
  def render_form(repository, groups)
    render(:action => :edit, :locals => {
        :project => ProjectPresenter.new(project),
        :groups => groups
      })
  end

  def load_authorized_project
    project = authorize_access_to(Project.find_by_slug!(params[:id]))
    unless admin?(current_user, project)
      flash[:error] = I18n.t("repositories_controller.adminship_error")
      target = project_path(project)
      redirect_to(target) and return
    end
    project
  end

  def project
    @project ||= Project.find_by_slug!(params[:id])
  end
end
