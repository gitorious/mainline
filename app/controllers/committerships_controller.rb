# encoding: utf-8
#-
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

class CommittershipsController < ApplicationController
  include RepositoryMembershipsUtils
  before_filter :find_repository_owner
  before_filter :find_repository
  before_filter :require_adminship
  renders_in_site_specific_context

  def index
    render_index(@repository, @repository.committerships.new)
  end

  def create
    committership = @repository.committerships.new
    committership.committer = committer
    committership.creator = current_user
    committership.build_permissions(params[:permissions])

    if committership.save
      if committership.committer.is_a?(User)
        flash[:success] = "User added as committer"
      else
        flash[:success] = "Team added as committers"
      end
      redirect_to([@repository.project, @repository, :committerships])
    else
      render_index(@repository, committership)
    end
  end

  def edit
    render_edit(@repository, @repository.committerships.find(params[:id]))
  end

  def update
    committership = @repository.committerships.find(params[:id])

    if !params[:permissions].blank?
      committership.build_permissions(params[:permissions])
    else
      flash[:error] = "No permissions selected"
      render_edit(@repository, committership) and return
    end

    if committership.save
      flash[:success] = "Permissions updated"
      redirect_to([@repository.project, @repository, :committerships])
    else
      render_edit(@repository, committership)
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
    redirect_to([@repository.project, @repository, :committerships])
  end

  protected
  def require_adminship
    unless admin?(current_user, @repository)
      respond_to do |format|
        format.html {
          flash[:error] = I18n.t "repositories_controller.adminship_error"
          redirect_to([@repository.project, @repository])
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

  def committer
    if params.key?(:user) && params[:user][:login]
      return User.find_by_login(params[:user][:login])
    end
    Team.find_by_name!(params[:group][:name])
  end

  def render_index(repository, committership)
    render(:index, :locals => {
        :repository => RepositoryPresenter.new(repository),
        :committership => committership,
        :committerships => repository.committerships.reject(&:new_record?),
        :memberships => repository.content_memberships
      })
  end

  def render_edit(repository, committership)
    render("edit", :locals => {
        :repository => repository,
        :committership => committership
      })
  end

  # For memberships
  helper_method :memberships_path
  helper_method :membership_path
  helper_method :new_membership_path
  helper_method :content_path
  helper_method :content
end
