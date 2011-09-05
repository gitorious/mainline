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

class MembershipsController < ApplicationController
  before_filter :find_group
  before_filter :ensure_group_adminship, :except => [:index, :show, :auto_complete_for_user_login]
  renders_in_global_context

  def index
    @memberships = paginate(page_free_redirect_options) do
      @group.memberships.paginate(:all, :page => params[:page])
    end

    @root = Breadcrumb::Memberships.new(@group)
  end

  def show
    redirect_to group_memberships_path(@group)
  end

  def new
    @membership = @group.memberships.new
    @root = Breadcrumb::NewMembership.new(@group)
  end

  def create
    @membership = Membership.build_invitation(current_user,
      :group  => @group,
      :user   => User.find_by_login!(params[:user][:login]),
      :role   => Role.find(params[:membership][:role_id]))
    @root = Breadcrumb::NewMembership.new(@group)
    if @membership.save
      flash[:success] = I18n.t("memberships_controller.membership_created")
      redirect_to group_memberships_path(@group)
    else
      render :action => "new"
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "No user was found with that username"
    @membership = @group.memberships.new
    render :action => "new"
  end

  def edit
    @membership = @group.memberships.find(params[:id])
  end

  def update
    @membership = @group.memberships.find(params[:id])
    @membership.role_id = params[:membership][:role_id]

    if @membership.save
      flash[:success] = I18n.t("memberships_controller.membership_updated")
      redirect_to group_memberships_path(@group)
    else
      render :action => "edit"
    end
  end

  def destroy
    @membership = @group.memberships.find(params[:id])

    if @membership.destroy
      flash[:success] = I18n.t("memberships_controller.membership_destroyed")
    else
      flash[:error] = I18n.t("memberships_controller.failed_to_destroy")
    end
    redirect_to group_memberships_path(@group)
  end

  def auto_complete_for_user_login
    @users = User.find(:all,
      :conditions => [ 'LOWER(login) LIKE ?', '%' + params[:q].downcase + '%' ],
      :limit => 10)
    render :text => @users.map{|u| u.login }.join("\n")
    #render :layout => false
  end


  protected
    def find_group
      @group = Group.find_by_name!(params[:group_id])
    end

    def ensure_group_adminship
      unless @group.admin?(current_user)
        access_denied and return
      end
    end
end
