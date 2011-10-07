# encoding: utf-8
#--
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
  PAGES = [:about, :faq, :contact, :tos, :privacy_policy]
  skip_before_filter :public_and_logged_in, :only => [:index].concat(PAGES)
  before_filter :login_required, :only => [:dashboard]
  renders_in_site_specific_context :except => PAGES
  renders_in_global_context :only => PAGES

  def index
    if !current_site.subdomain.blank?
      render_site_index and return
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
  end

  def faq
  end

  def contact
  end

  protected

    # Render a Site-specific index template
    def render_site_index
      @projects = current_site.projects.find(:all, :order => "created_at asc")
      @teams = Group.all_participating_in_projects(@projects)
      @top_repository_clones = Repository.most_active_clones_in_projects(@projects)
      @latest_events = Event.latest_in_projects(25, @projects.map{|p| p.id })
      render "site/#{current_site.subdomain}/index"
    end

    def render_public_timeline
      @projects = Project.find(:all, :limit => 10, :order => "id desc")
      @top_repository_clones = Repository.most_active_clones
      @active_projects = Project.most_active_recently(15)
      @active_users = User.most_active
      @active_groups = Group.most_active
      @latest_events = Event.latest(25)
      render :template => "site/index"
    end

    def render_dashboard
      @user = current_user
      @projects = @user.projects.find(:all,
        :include => [:tags, { :repositories => :project }])
      @repositories = current_user.commit_repositories
      @events = @user.paginated_events_in_watchlist(:page => params[:page])
      @messages = @user.messages_in_inbox(3)
      @favorites = @user.watched_objects
      @root = Breadcrumb::Dashboard.new(@user)
      @atom_auto_discovery_url = watchlist_user_path(@user, :format => :atom)

      render :template => "site/dashboard"
    end

    def render_gitorious_dot_org_in_public
      @feed_items = Rails.cache.fetch("blog_feed:feed_items", :expires_in => 1.hour) do
        BlogFeed.new("http://blog.gitorious.org/feed/").fetch
      end
      render :template => "site/public_index", :layout => "second_generation/application"
    end

    # Render the global index template
    def render_global_index
      if logged_in?
        render_dashboard
      elsif GitoriousConfig["is_gitorious_dot_org"]
        render_gitorious_dot_org_in_public
      else
        render_public_timeline
      end
    end
end
