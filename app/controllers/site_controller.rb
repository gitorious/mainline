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
  
  def index
    @projects = if GitoriousConfig['gitorious_public_registration'] || logged_in?
      Project.find(:all, :limit => 10, :order => "id desc")
    else
      []
    end
  end
  
  def dashboard
    @projects = current_user.projects
    @repositories = current_user.repositories.find(:all, 
      :conditions => ["mainline = ?", false])
    event_project_ids = (@projects.map(&:id) + @repositories.map(&:project_id)).uniq
    @events = Event.paginate(:all, 
      :page => params[:page],
      :conditions => ["events.project_id in (?)", event_project_ids], 
      :order => "events.created_at desc", 
      :include => [:user, :project])    
  end
  
  def about
  end
  
  def faq    
  end
  
end
