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
  install_site_before_filters
  
  def index
    if !current_site.subdomain.blank?
      @projects = current_site.projects.find(:all, :limit => 10, :order => "id desc")
      render "site/#{current_site.subdomain}/index"
    else
      @projects = if GitoriousConfig['public_mode'] || logged_in?
        Project.find(:all, :limit => 10, :order => "id desc")
      else
        []
      end
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
