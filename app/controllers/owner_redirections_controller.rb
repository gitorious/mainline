# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class OwnerRedirectionsController < ApplicationController
  def show
    path = params[:slug].split("/")

    if repository = owner.repositories.find_by_name(path[1])
      return redirect_to "/#{path.join("/")}"
    end

    if owner.projects.find_by_slug(path[0])
      return redirect_to("/#{path.join('/')}")
    end

    if repository = owner.repositories.find_by_name(path[0])
      return redirect_to("/#{repository.project.to_param}/#{path.join('/')}")
    end

    render_not_found
  end

  private
  def owner
    return @owner if @owner

    if params.key?(:user_id)
      @owner = User.find_by_login!(params[:user_id])
    else
      @owner = Group.find_by_name!(params[:group_id])
    end
  end
end
