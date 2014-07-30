# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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
require "gitorious/app"

class RepositoriesController < ApplicationController
  include Gitorious::View::DoltUrlHelper
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_repository_owner
  before_filter :find_and_require_repository_adminship, :only => [:edit, :update, :destroy]
  renders_in_site_specific_context

  def show
    repository = authorize_access_to(@project.repositories.find_by_name!(params[:id]))

    if !repository.ready?
      response.headers["Refresh"] = "3"
      render(:action => "show", :locals => {
          :repository => repository,
          :atom_auto_discovery_url => activities_project_repository_path(repository.project, repository, :format => :atom),
          :atom_auto_discovery_title => "#{repository.title} ATOM feed"
        }) and return
    end

    respond_to do |format|
      format.html do
        repo = RepositoryPresenter.new(repository)

        if params['go-get']
          render 'go-get', locals: { repository: repository }, layout: false
        else
          redirect_to(tree_entry_url(repo.slug, repository.head.commit, ""), status: 307)
        end
      end

      format.xml do
        render :xml => repository.to_xml
      end
    end
  end

  def index
    respond_to do |format|
      format.html { redirect_to(project_path(@project)) }

      if term = params[:filter]
        repositories = filter(@project.search_repositories(term))
      else
        repositories = filter(@owner.repositories.regular.includes(:project, :user))
      end

      format.xml {render :xml => repositories.to_xml}
      format.json {render :json => RepositorySerializer.new(self).to_json(repositories)}
    end
  end

  def new
    outcome = PrepareProjectRepository.new(self, @project, current_user).execute({})
    params[:private] = Gitorious.repositories_default_private?
    pre_condition_failed(outcome)
    outcome.success { |result| render_form(result, @project) }
  end

  def create
    cmd = CreateProjectRepository.new(Gitorious::App, @project, current_user)
    outcome = cmd.execute({ :private => params[:private] }.merge(params[:repository]))

    pre_condition_failed(outcome) do |f|
      f.when(:admin_required) { |c| respond_denied_and_redirect_to(@project) }
    end

    outcome.failure do |repository|
      render_form(repository, @project)
    end

    outcome.success do |result|
      flash[:success] = I18n.t("repositories_controller.create_success")
      redirect_to([result.project, result])
    end
  end

  def edit
    render_edit_form(@repository)
  end

  def update
    Repository.transaction do
      @repository.head = params[:repository][:head]
      @repository.log_changes_with_user(current_user) do
        @repository.replace_value(:name, params[:repository][:name])
        @repository.replace_value(:description, params[:repository][:description], true)
      end
      @repository.notify_committers_on_new_merge_request = params[:repository][:notify_committers_on_new_merge_request]
      @repository.deny_force_pushing = !params[:force_pushing]
      @repository.merge_requests_enabled = params[:repository][:merge_requests_enabled]
      validation = RepositoryValidator.call(@repository)
      return render_edit_form(Repository.find(@repository.id), validation) if !validation.valid?
      @repository.save!
      flash[:success] = "Repository updated"
      redirect_to [@repository.project, @repository]
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    edit
  end

  def confirm_delete
    repository = authorize_access_to(@owner.repositories.find_by_name!(params[:id]))
    unless can_delete?(current_user, repository)
      flash[:error] = I18n.t("repositories_controller.adminship_error")
      redirect_to(@owner) and return
    end
    render("confirm_delete", :locals => {
        :repository => RepositoryPresenter.new(repository)
      })
  end

  def destroy
    @repository = find_repository
    if can_delete?(current_user, @repository)
      repo_name = @repository.name
      flash[:notice] = I18n.t "repositories_controller.destroy_notice"
      @repository.destroy
      @repository.project.create_event(Action::DELETE_REPOSITORY, @owner,
        current_user, repo_name)
    else
      flash[:error] = I18n.t "repositories_controller.destroy_error"
    end
    redirect_to @owner
  end

  private
  def render_form(repository, project)
    render(:action => :new, :locals => {
        :repository => repository,
        :project => ProjectPresenter.new(project)
      })
  end

  def render_edit_form(repository, repo_edit = nil)
    render(:action => :edit, :locals => {
        :repository => RepositoryPresenter.new(repository),
        :heads => repository.git.heads,
        :repo_edit => repo_edit || repository
      })
  end

  def find_and_require_repository_adminship
    @repository = @owner.repositories.find_by_name_in_project!(params[:id],
      @containing_project)
    unless admin?(current_user, authorize_access_to(@repository))
      respond_denied_and_redirect_to(project_repository_path(@repository.project, @repository))
      return
    end
  end

  def respond_denied_and_redirect_to(target)
    respond_to do |format|
      format.html {
        flash[:error] = I18n.t "repositories_controller.adminship_error"
        redirect_to(target)
      }
      format.xml  {
        render :text => I18n.t( "repositories_controller.adminship_error"),
        :status => :forbidden
      }
    end
  end

  def find_repository
    repo = @owner.repositories.find_by_name_in_project!(params[:id], @containing_project)
    authorize_access_to(repo)
  end

  def pre_condition_failed(outcome)
    super(outcome) do |f|
      f.when(:admin_required) { |c| respond_denied_and_redirect_to(@project) }
    end
  end
end
