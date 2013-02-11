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

class GroupsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_group_and_ensure_group_adminship, :only => [:edit, :update, :avatar]
  before_filter :check_if_only_site_admins_can_create, :only => [:new, :create]
  renders_in_global_context

  def index
    @groups = paginate(:action => "index") do
      Team.paginate_all(params[:page])
    end
  end

  def show
    @group = Team.find_by_name!(params[:id])
    @mainlines = filter(@group.repositories.mainlines)
    @clones = filter(@group.repositories.clones)
    @projects = filter(@group.projects)
    @memberships = Team.memberships(@group)
    @events = paginate(:action => "show", :id => params[:id]) do
      filter_paginated(params[:page], 30) do |page|
        Team.events(@group, page)
      end
    end
  end

  def new
    @group = Team.new_group
  end

  def edit
  end

  def update
    Team.update_group(@group, params)
    redirect_to group_path(@group)
    rescue ActiveRecord::RecordInvalid
      render :action => 'edit'
  end

  def create
    @group = Team.create_group(params, current_user)
    @group.save!
    flash[:success] = I18n.t "groups_controller.group_created"
    redirect_to group_path(@group)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    render :action => "new"
  end

  def destroy
    begin
      Team.destroy_group(params[:id], current_user)
      flash[:success] = "The team was deleted"
      redirect_to groups_path
    rescue Team::DestroyGroupError => e
      flash[:error] = e.message
      redirect_to group_path(params[:id])
    end
  end

  # DELETE avatar
  def avatar
    Team.delete_avatar(@group)
    flash[:success] = "The team image was deleted"
    redirect_to group_path(@group)
  end

  # TODO: Remove? Don't thing it's used
  # def auto_complete_for_project_slug
  #   @projects = filter(Project.find(:all,
  #     :conditions => ['LOWER(slug) LIKE ?', "%#{params[:project][:slug].downcase}%"],
  #     :limit => 10))
  #   render :layout => false
  # end

  protected
  def find_group_and_ensure_group_adminship
    @group = Team.find_by_name!(params[:id])
    unless admin?(current_user, @group)
      access_denied and return
    end
  end

  def check_if_only_site_admins_can_create
    if GitoriousConfig["only_site_admins_can_create_teams"]
      unless site_admin?(current_user)
        flash[:error] = "Only site administrators may create teams"
        redirect_to :action => "index"
        return false
      end
    end
  end
end
