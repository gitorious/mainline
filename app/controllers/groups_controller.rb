# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
    begin
      groups, total_pages, page = paginated_groups
    rescue RangeError
      flash[:error] = "Page #{params[:page] || 1} does not exist"
      redirect_to(groups_path, :status => 307) and return
    end

    render("index", :locals => {
        :groups => groups,
        :page => page,
        :total_pages => total_pages
      })
  end

  def show
    group = Team.find_by_name!(params[:id])
    events = paginate(:action => "show", :id => params[:id]) do
      filter_paginated(params[:page], 30) do |page|
        Team.events(group, page)
      end
    end

    return if params.key?(:page) && events.length == 0

    render("show", :locals => {
        :group => group,
        :mainlines => filter(group.repositories.mainlines),
        :clones => filter(group.repositories.clones),
        :projects => filter(group.projects),
        :memberships => Team.memberships(group),
        :events => events
      })
  end

  def new
    render("new", :locals => { :group => Team.new_group })
  end

  def edit
    render("edit", :locals => { :group => @group })
  end

  def update
    Team.update_group(@group, params)
    flash[:success] = 'Team was updated'
    redirect_to(group_path(@group))
  rescue ActiveRecord::RecordInvalid
    render(:action => "edit", :locals => { :group => @group })
  end

  def create
    group = Team.create_group(params, current_user)
    group.save!
    flash[:success] = I18n.t("groups_controller.group_created")
    redirect_to group_path(group)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    render("new", :locals => { :group => group })
  end

  def destroy
    begin
      Team.destroy_group(params[:id], current_user)
      flash[:success] = "The team was deleted"
      redirect_to(groups_path)
    rescue Team::DestroyGroupError => e
      flash[:error] = e.message
      redirect_to(group_path(params[:id]))
    end
  end

  # DELETE avatar
  def avatar
    Team.delete_avatar(@group)
    flash[:success] = "The team image was deleted"
    redirect_to(group_path(@group))
  end

  protected
  def find_group_and_ensure_group_adminship
    @group = Team.find_by_name!(params[:id])
    unless admin?(current_user, @group)
      access_denied and return
    end
  end

  def check_if_only_site_admins_can_create
    if Gitorious.restrict_team_creation_to_site_admins?
      unless site_admin?(current_user)
        flash[:error] = "Only site administrators may create teams"
        redirect_to(:action => "index")
        return false
      end
    end
  end

  def paginated_groups
    page = (params[:page] || 1).to_i
    groups, pages = JustPaginate.paginate(page, 50, Team.count) do |range|
      Team.offset(range.first).limit(range.count).order_by_name
    end
    [groups, pages, page]
  end
end
