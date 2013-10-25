# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
    redirect_to(user_edit_favorites_path(current_user))
  end

  def update
    @favorite = authorize_access_to(current_user.favorites.find(params[:id]))
    @favorite.notify_by_email = params[:favorite][:notify_by_email]
    @favorite.save

    respond_to do |wants|
      wants.html do
        redirect_to user_edit_favorites_path(current_user)
      end

      wants.js { head :ok }
    end
  end

  def create
    @favorite = @watchable.watched_by!(current_user)
    @favorite.create_event

    respond_to do |wants|
      wants.html do
        redirect_to :back
      end

      wants.js do
        render :status => :created, :nothing => true,
          :location => polymorphic_path(@favorite)
      end
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |wants|
      wants.html do
        flash[:error] = "Failed to watch the object"
        redirect_to :back
      end

      wants.js do
        render :status => :unprocessable_entity, :nothing => true
      end
    end
  end

  def destroy
    @favorite = authorize_access_to(current_user.favorites.find(params[:id]))
    @favorite.destroy
    watchable = @favorite.watchable
    respond_to do |wants|
      wants.html do
        redirect_to :back
      end

      wants.js do
        head :ok, :location => url_for(:action => "create", :watchable_id => watchable.id,
          :watchable_type => watchable.class.name, :only_path => true)
      end
    end
  end

  private

  def find_watchable
    watchable_type = params[:watchable_type]
    if allowed_watchables.include?(watchable_type)
      watchable_class = watchable_type.constantize
    else
      raise ActiveRecord::RecordNotFound
    end
    @watchable = authorize_access_to(watchable_class.find(params[:watchable_id]))
  end

  def allowed_watchables
    ActiveRecord::Base.descendants.select { |klass| klass < Watchable }.map(&:name)
  end
end
