# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2008 Cairo Noleto <caironoleto@gmail.com>
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
require "project_xml_serializer"

class ProjectsController < ApplicationController
  include ProjectFilters

  before_filter :login_required,
    :only => [:create, :update, :destroy, :new, :edit, :confirm_delete]
  before_filter :find_project,
    :only => [:show, :edit, :update, :confirm_delete, :destroy, :edit_slug]
  before_filter :require_admin, :only => [:edit, :update, :edit_slug]
  before_filter :require_user_has_ssh_keys, :only => [:new, :create]

  renders_in_site_specific_context :only => [:show, :edit, :update, :confirm_delete]
  renders_in_global_context :except => [:show, :edit, :update, :confirm_delete]

  def projects_sorting
    Sorting.new(params[:order], view_context, 'sortings/projects',
                {name: :alphabetical, order: ->(q){ q.order_by_title }},
                {name: :activity, order: ->(q){ q.order_by_activity }, default: true})
  end

  def repositories_sorting
    Sorting.new(params[:repositories_order], view_context, 'sortings/repositories',
                {name: :ascending, order: ->(q){ q.sort_by(&:url_path) }, default: true },
                {name: :descending, order: ->(q){ q.sort_by(&:url_path).reverse }})
  end

  def index
    begin
      projects, total_pages, page = paginated_projects
    rescue RangeError
      flash[:error] = "Page #{page} does not exist"
      redirect_to(projects_path, :status => 307) and return
    end

    respond_to do |format|
      format.html do
        render(:index, :locals => {
            :atom_auto_discovery_url => projects_path(:format => :atom),
            :projects => projects,
            :total_pages => total_pages,
            :page => page,
            :active_recently => filter(Project.most_active_recently),
            :sorting => projects_sorting,
            :tags => Project.top_tags
          })
      end

      format.xml do
        render(:xml => ProjectXMLSerializer.new(self, projects).render(current_user))
      end

      format.atom { render(:index, :locals => { :projects => projects }) }
    end
  end

  def show
    begin
      page = (params[:page] || 1).to_i
      events, total_pages = paginated_events(@project, page)
    rescue RangeError
      flash[:error] = "Page #{page} does not exist"
      redirect_to(project_path(@project), :status => 307) and return
    end

    mainlines = filter(by_push_time(@project.repositories.mainlines))
    group_clones = filter(@project.recently_updated_group_repository_clones)
    user_clones = filter(@project.recently_updated_user_repository_clones)

    respond_to do |format|
      format.html do
        render(:show, :locals => {
            :active => :activities,
            :project => ProjectPresenter.new(@project),
            :events => events,
            :current_page => page,
            :total_pages => total_pages,
            :atom_auto_discovery_url => project_path(@project, :format => :atom),
            :mainlines => repositories_sorting.apply(mainlines),
            :mainlines_sorting => repositories_sorting,
            :group_clones => group_clones,
            :user_clones => user_clones
          }, :layout => 'project')
      end

      format.xml do
        render(:xml => @project.to_xml({}, mainlines, group_clones + user_clones))
      end

      format.atom do
        render(:show, :locals => {
            :project => @project,
            :events => events
          })
      end
    end
  end

  def new
    outcome = PrepareProject.new(self, current_user).execute({})
    params[:private] = Gitorious.projects_default_private?
    pre_condition_failed(outcome)
    outcome.success { |result| render_form(result) }
  end

  def create
    input = { :private => params[:private] }.merge(params[:project])
    outcome = CreateProject.new(Gitorious::App, current_user).execute(input)

    outcome.success do |project|
      redirect_to(new_project_repository_path(project))
    end

    pre_condition_failed(outcome)

    outcome.failure do |project|
      render_form(project)
    end
  end

  def edit
    render_edit_form(@project)
  end

  def edit_slug
    if request.put?
      @project.slug = params[:project][:slug]
      begin
        @project.save
        @project.create_event(Action::UPDATE_PROJECT, @project, current_user)
        flash[:success] = "Project slug updated"
        redirect_to(:action => :show, :id => @project.slug) and return
      rescue ActiveRecord::RecordNotUnique
        @project.reload
        flash[:error] = "The slug isn't unique"
      end
    end
    render("edit_slug", :locals => { :project => @project })
  end

  def update
    outcome = UpdateProject.new(current_user, @project).execute(params[:project])

    outcome.success do |project|
      flash[:success] = "Project details updated"
      redirect_to(project)
    end

    pre_condition_failed(outcome)

    outcome.failure do |validator|
      flash[:error] = "Failed to update the project"
      render_edit_form(validator)
    end
  end

  def confirm_delete
    project = authorize_access_to(Project.find_by_slug!(params[:id]))
    unless admin?(current_user, project)
      flash[:error] = I18n.t("repositories_controller.adminship_error")
      redirect_to(root_path) and return
    end
    unless can_delete?(current_user, project)
      flash[:error] = "Project cannot be deleted as long as there are repository clones under it"
      redirect_to(project_path) and return
    end
    render("confirm_delete", :locals => {
        :project => ProjectPresenter.new(project)
      })
  end

  def destroy
    if can_delete?(current_user, @project)
      @project.destroy
      flash[:notice] = "The project and its repositories were deleted."
    else
      flash[:error] = I18n.t("projects_controller.destroy_error")
    end
    redirect_to projects_path
  end

  protected

  def render_form(project)
    render(:action => :new, :locals => { :project => project })
  end

  def render_edit_form(project)
    render(:action => :edit, :locals => { :project => project })
  end

  def pre_condition_failed(outcome)
    super(outcome) do |f|
      f.otherwise do |pc|
        key = "projects_controller.create_only_for_site_admins"
        flash[:error] = I18n.t(key) if pc.is_a?(ProjectProposalRequired)
        redirect_to(new_admin_project_proposal_path)
      end
    end
  end

  def by_push_time(repositories)
    repositories.sort_by { |ml| ml.last_pushed_at || Time.utc(1970) }.reverse
  end

  def paginated_events(project, page)
    scope = Event.where("project_id = ?", project.id).where("target_type != ?", "Event")
    JustPaginate.paginate(page, Event.per_page, scope.count) do |range|
      events = scope.
        order("created_at desc").
        includes(:user, :project).
        offset(range.first).
        limit(range.count)
      Gitorious.private_repositories? ? filter(events) : events
    end
  end

  def paginated_projects
    page = (params[:page] || 1).to_i
    projects, pages = JustPaginate.paginate(page, Project.per_page, Project.active_count) do |range|
      unordered = Project.
        active.offset(range.first).limit(range.count).
        includes(:tags, { :repositories => :project })

      projects_sorting.apply(unordered)
    end
    projects = filter(projects) if Gitorious.private_repositories?
    [projects, pages, page]
  end

end
