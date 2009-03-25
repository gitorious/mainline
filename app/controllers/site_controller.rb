#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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
    # Render a Site-specific template
    if !current_site.subdomain.blank?
      @projects = current_site.projects.find(:all, :limit => 10, :order => "id desc")
      @teams = Group.all_participating_in_projects(@projects)
      @top_repository_clones = Repository.most_active_clones_in_projects(@projects)
      expires_in 10.minutes
      render "site/#{current_site.subdomain}/index" 
      return
    end
    
    last_event = Event.latest(1).first || Project.first
    if last_event.nil? || stale_conditional?(last_event, last_event.created_at)
      @projects = Project.find(:all, :limit => 10, :order => "id desc")
      @top_repository_clones = Repository.most_active_clones
      @active_recently = Project.most_active_recently
      @active_overall = Project.most_active_overall(@active_recently.size)
      @active_users = User.most_active
      @active_groups = Group.most_active
      @latest_events = Event.latest(15)
      expires_in 10.minutes
    end
  end
  
  def dashboard
    redirect_to current_user
  end
  
  def about
  end
  
  def faq    
  end
  
end
