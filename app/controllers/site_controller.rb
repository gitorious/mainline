# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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

class SiteController < ApplicationController
  skip_before_filter :public_and_logged_in, :only => [:index, :about, :faq, :contact, :tos, :privacy_policy]

  before_filter :login_required, :only => [:dashboard, :my_activities]
  before_filter :load_dashboard, :only => [:index, :my_activities]

  renders_in_site_specific_context :except => [:about, :faq, :contact, :tos, :privacy_policy]
  renders_in_global_context :only => [:about, :faq, :contact, :tos, :privacy_policy]

  attr_reader :dashboard_presenter

  def index
    if !current_site.subdomain.blank?
      render_site_index
    else
      render_global_index
    end
  end

  def public_timeline
    render_public_timeline
  end

  def dashboard
    redirect_to current_user
  end

  def about
    render :about
  end

  def faq
    render :faq
  end

  def contact
    render :contact
  end

  def my_activities
    render_dashboard('my-activities')
  end

  protected

  # Render a Site-specific index template
  def render_site_index
    projects = filter(current_site.projects.order("created_at asc"))

    respond_to do |format|
      format.html do
        render "site/#{current_site.subdomain}/index", :locals => {
          :projects => projects,
            :teams => Group.all_participating_in_projects(projects),
            :top_repository_clones => filter(Repository.most_active_clones_in_projects(projects)),
            :latest_events => filter(Event.latest_in_projects(25, projects.map { |p| p.id }))
        }
      end
    end
  end

  def render_public_timeline
    @projects = filter(Project.order("id desc").limit(10))
    @top_repository_clones = filter(Repository.most_active_clones)
    @active_projects = filter(Project.most_active_recently(15))
    @active_users = User.most_active
    @active_groups = Group.most_active
    @latest_events = filter(Event.latest(25))

    respond_to do |format|
      format.html do
        render :template => "site/index"
      end
    end
  end

  def render_dashboard(active_tab = 'activities')
    @user = current_user

    events =
      if active_tab == 'my-activities'
        dashboard_presenter.user_events(params[:page])
      else
        dashboard_presenter.events(params[:page])
      end

    paginate(page_free_redirect_options) do
      respond_to do |format|
        format.html do
          render :template => 'site/dashboard', :locals => {
            :active_tab => active_tab,
            :user => dashboard_presenter.user,
            :events => events,
            :current_page => events.current_page,
            :total_pages => events.total_pages,
            :projects => dashboard_presenter.projects,
            :repositories => dashboard_presenter.repositories,
            :favorites => dashboard_presenter.favorites,
            :atom_auto_discovery_url => dashboard_presenter.atom_auto_discovery_url
          }, :layout => !pjax_request?
        end
      end
    end
  end

  def render_gitorious_dot_org_in_public
    @feed_items = Rails.cache.fetch("blog_feed:feed_items", :expires_in => 1.hour) do
      unless Rails.env.test?
        BlogFeed.new("http://blog.gitorious.org/feed/").fetch
      else
        []
      end
    end

    respond_to do |format|
      format.html { render :template => "site/public_index" }
    end
  end

  # Render the global index template
  def render_global_index
    if logged_in?
      render_dashboard
    elsif Gitorious.dot_org?
      render_gitorious_dot_org_in_public
    else
      render_public_timeline
    end
  end

  def load_dashboard
    @current_dashboard = Dashboard.new(current_user)
    @dashboard_presenter = DashboardPresenter.new(@current_dashboard, authorized_filter, self)
  end

end
