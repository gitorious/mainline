# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

  def index
    @favorites = current_user.favorites.all(:include => :watchable)
    @root = Breadcrumb::Favorites.new(current_user)
  end

  def update
    @favorite = current_user.favorites.find(params[:id])
    @favorite.notify_by_email = params[:favorite][:notify_by_email]
    @favorite.save
    respond_to do |wants|
      wants.html { redirect_to favorites_path }
      wants.js { head :ok }
    end
  end

  def create
    @favorite = @watchable.watched_by!(current_user)
    @favorite.create_event
    respond_to do |wants|
      wants.html {
        flash[:notice] = "You are now watching this #{@watchable.class.name.downcase}"
        redirect_to repo_owner_path(@watchable, [@watchable.project, @watchable])
      }
      wants.js {
        render :status => :created, :nothing => true,
          :location => polymorphic_path(@favorite)
      }
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
      wants.js {
        head :ok, :location => url_for(:action => "create", :watchable_id => watchable.id,
          :watchable_type => watchable.class.name, :only_path => true)
      }
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

