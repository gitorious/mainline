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
  skip_before_filter :public_and_logged_in, :only => [:index, :about, :faq]
  before_filter :login_required, :only => [:dashboard]
  renders_in_site_specific_context
  
  def index
    if !current_site.subdomain.blank?
      render_site_index and return
    else
      render_global_index
    end
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
      @projects = current_site.projects.find(:all, :limit => 10, :order => "id desc")
      # pick the newest event
      top_events = @projects.map{|p| p.events.first(:order => "id desc") }.flatten.compact
      last_event = (top_events.empty? ? @projects : top_events).max do |a,b| 
        a.created_at <=> b.created_at
      end
      
      if stale_conditional?(last_event, last_event.created_at)
        @teams = Group.all_participating_in_projects(@projects)
        @top_repository_clones = Repository.most_active_clones_in_projects(@projects)
        @latest_events = Event.latest_in_projects(15, @projects.map{|p| p.id })
        render "site/#{current_site.subdomain}/index"
      end
    end

    # Render the global index template
    def render_global_index
      last_event = Event.latest(1).first || Project.first
      if last_event.nil? || stale_conditional?(last_event, last_event.created_at)
        @projects = Project.find(:all, :limit => 10, :order => "id desc")
        @top_repository_clones = Repository.most_active_clones
        @active_recently = Project.most_active_recently
        @active_overall = Project.most_active_overall(@active_recently.size)
        @active_users = User.most_active
        @active_groups = Group.most_active
        @latest_events = Event.latest(25)
      end
    end
  
end
