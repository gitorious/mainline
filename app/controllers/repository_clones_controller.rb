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

class RepositoryClonesController < ApplicationController
  include Gitorious::Messaging::Publisher

  before_filter :login_required
  before_filter :require_user_has_ssh_keys

  renders_in_site_specific_context

  def new
    outcome = execute_use_case(PrepareRepositoryClone)
    outcome.success { |clone| render_form(clone) }
  end

  def create
    outcome = execute_use_case(CloneRepository, params[:repository])

    outcome.failure do |clone|
      respond_to do |format|
        format.html { render_form(clone) }
        format.xml { render :xml => clone.errors, :status => :unprocessable_entity }
      end
    end

    outcome.success do |clone|
      location = project_repository_path(clone.project, clone)
      respond_to do |format|
        format.html { redirect_to(location) }
        format.xml { render :xml => clone, :status => :created, :location => location }
      end
    end
  end

  private
  def execute_use_case(use_case, input = {})
    project = Project.find_by_slug!(params[:project_id])
    repositories = project.repositories.find_by_name!(params[:id])
    outcome = use_case.new(self, repositories, current_user).execute(input)

    pre_condition_failed(outcome) do |f|
      f.when(:commits_required) { |c| commits_required(repositories) }
    end

    outcome
  end

  def render_form(clone)
    render(:action => "new", :locals => {
        :repository => clone.parent,
        :clone => clone,
        :project => clone.project
      })
  end

  def commits_required(repository)
    respond_to do |format|
      format.html do
        flash[:error] = I18n.t("repositories_controller.create_clone_error")
        redirect_to [repository.project, repository]
      end
      format.xml do
        render :text => I18n.t("repositories_controller.create_clone_error"),
        :location => [repository.project, repository], :status => :unprocessable_entity
      end
    end
  end
end
