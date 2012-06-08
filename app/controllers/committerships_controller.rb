# encoding: utf-8
#-
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

class CommittershipsController < ApplicationController
  before_filter :find_repository_owner
  before_filter :find_repository
  before_filter :require_adminship
  renders_in_site_specific_context

  def index
    @committerships = paginate(page_free_redirect_options) do
      @repository.committerships.paginate(:all, :page => params[:page])
    end

    @root = Breadcrumb::Committerships.new(@repository)
  end

  def new
    @committership = @repository.committerships.new
  end

  def create
    @committership = @repository.committerships.new
    if params[:group][:name].blank? && !params[:user][:login].blank?
      @committership.committer = User.find_by_login(params[:user][:login])
    else
      @committership.committer = Team.find_by_name!(params[:group][:name])
    end
    @committership.creator = current_user
    @committership.build_permissions(params[:permissions])

    if @committership.save
      if @committership.committer.is_a?(User)
        flash[:success] = "User added as committer"
      else
        flash[:success] = "Team added as committers"
      end
      redirect_to([@owner, @repository, :committerships])
    else
      render :action => "new"
    end
  end

  def edit
    @committership = @repository.committerships.find(params[:id])
  end

  def update
    @committership = @repository.committerships.find(params[:id])
    if !params[:permissions].blank?
      @committership.build_permissions(params[:permissions])
    else
      flash[:error] = "No permissions selected"
      render("edit") and return
    end

    if @committership.save
      flash[:success] = "Permissions updated"
      redirect_to([@owner, @repository, :committerships])
    else
      render "edit"
    end
  end

  def destroy
    @committership = @repository.committerships.find(params[:id])

    # Update creator to hold the "destroyer" user account
    # Makes sure hooked-in event reports correct destroying user
    # We have no other way of passing destroying user along
    # except restructing code to not use implicit event hooks.
    @committership.creator = current_user
    
    if @committership.destroy
      flash[:notice] = "The committer was removed."
    end
    redirect_to([@owner, @repository, :committerships])
  end

  protected
  def require_adminship
    unless admin?(current_user, @repository)
      respond_to do |format|
        format.html {
          flash[:error] = I18n.t "repositories_controller.adminship_error"
          redirect_to([@owner, @repository])
        }
        format.xml  {
          render :text => I18n.t( "repositories_controller.adminship_error"),
          :status => :forbidden
        }
      end
      return
    end
  end

  def find_repository
    @repository = @owner.repositories.find_by_name_in_project!(params[:repository_id],
                                                               @containing_project)
    authorize_access_to(@repository)
    authorize_access_to(@repository.project)
  end
end
