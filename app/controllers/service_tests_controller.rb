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

class ServiceTestsController < ApplicationController
  before_filter :login_required

  def create
    hook = repository.services.find(params[:service_id])
    outcome = TestService.new(Gitorious::App, hook, current_user).execute
    pre_condition_failed(outcome)
    outcome.failure do |validation|
      flash[:error] = validation.errors.full_messages.join(", ")
      redirect_back(hook)
    end
    outcome.success do |hook|
      flash[:notice] = "Payload sent to #{hook.adapter.name}"
      redirect_back(hook)
    end
  end

  private
  def redirect_back(hook)
    repo = hook.repository
    redirect_to(project_repository_services_path(repo.project, repo))
  end

  def repository
    return @repository if @repository
    project = authorize_access_to(Project.find_by_slug!(params[:project_id]))
    @repository = authorize_access_to(project.repositories.find_by_name!(params[:repository_id]))
  end
end
