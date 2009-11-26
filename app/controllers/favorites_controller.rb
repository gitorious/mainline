# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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

class FavoritesController < ApplicationController
  before_filter :login_required
  before_filter :find_watchable, :only => [:create]

  def create
    @favorite = current_user.favorites.create!(:watchable => @watchable)
    respond_to do |wants|
      wants.html {
        flash[:notice] = "You are now watching this #{@watchable.class.name.downcase}"
        redirect_to repo_owner_path(@watchable, [@watchable.project, @watchable])
      }
      wants.js {render :status => :created, :nothing => true,
        :location => polymorphic_path(@favorite)}
    end
  end

  def destroy
    @favorite = current_user.favorites.find(params[:id])
    @favorite.destroy
    watchable = @favorite.watchable
    respond_to do |wants|
      wants.html {
        flash[:notice] = "You no longer watch this #{watchable.class.name.downcase}"
        redirect_to repo_owner_path(watchable, [watchable.project, watchable])
      }
      wants.js {head :ok, :location => url_for(:action => "create", :watchable_id => watchable.id,
          :watchable_type => watchable.class.name, :only_path => true)}
    end
  end
  
  private
  def find_watchable
    begin
      watchable_class = params[:watchable_type].constantize
    rescue NameError
      raise ActiveRecord::RecordNotFound
    end
    @watchable = watchable_class.find(params[:watchable_id])
  end
end
