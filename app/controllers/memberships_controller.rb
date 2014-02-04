# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
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

class MembershipsController < ApplicationController
  before_filter :find_group
  before_filter :find_membership, :only => [:edit, :update, :destroy]
  before_filter :ensure_group_adminship, :except => [:index, :show, :create]
  renders_in_global_context

  def index
    memberships = paginate(page_free_redirect_options) do
      @group.memberships.paginate(:page => params[:page])
    end

    return if memberships.length == 0 && params.key?(:page)

    render("index", :locals => {
        :memberships => memberships,
        :group => @group,
        :total_pages => memberships.respond_to?(:total_pages) ? memberships.total_pages : 1,
        :page => memberships.respond_to?(:current_page) ? memberships.current_page : 1
      })
  end

  def show
    redirect_to(group_memberships_path(@group))
  end

  def new
    render_form(@group.memberships.new)
  end

  def create
    input = { :login => params[:membership][:login], :role => params[:membership][:role_id] }
    outcome = CreateMembership.new(self, @group, current_user).execute(input)

    pre_condition_failed(outcome) do |f|
      f.when(:admin_required) { |c| access_denied }
    end

    outcome.success do |result|
      flash[:success] = I18n.t("memberships_controller.membership_created")
      redirect_to group_memberships_path(@group)
    end

    outcome.failure do |membership|
      render_form(membership)
    end
  end

  def edit
    render_edit_form
  end

  def update
    outcome = UpdateMembership.new(@membership).execute(params[:membership])

    outcome.success do
      flash[:success] = I18n.t("memberships_controller.membership_updated")
      redirect_to group_memberships_path(@group)
    end

    outcome.failure do |membership|
      render_edit_form(membership)
    end
  end

  def destroy
    outcome = DestroyMembership.new(@membership).execute

    outcome.success do
      flash[:success] = I18n.t("memberships_controller.membership_destroyed")
    end

    outcome.pre_condition_failed do
      flash[:error] = I18n.t("memberships_controller.failed_to_destroy")
    end

    redirect_to group_memberships_path(@group)
  end

  protected

  def find_group
    @group = Team.find_by_name!(params[:group_id])
  end

  def find_membership
    @membership = @group.memberships.find(params[:id])
  end

  def ensure_group_adminship
    unless admin?(current_user, @group)
      access_denied and return
    end
  end

  def render_edit_form(membership = @membership)
    render("edit", :locals => { :membership => membership, :group => @group })
  end

  def render_form(membership)
    render(:action => "new", :locals => {
        :membership => membership,
        :group => @group,
        :login => params[:user] && params[:user][:login]
      })
  end
end
