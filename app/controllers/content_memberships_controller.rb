# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class ContentMembershipsController < ApplicationController
  before_filter :require_private_repos
  before_filter :login_required
  renders_in_site_specific_context :only => [:index]

  def create
    membership = content.content_memberships.new
    membership.member = member(params[:user], params[:group])
    membership.save
    redirect_to(redirect_options)
  rescue ActiveRecord::RecordNotFound => err
    m = err.message.match(/([^\s]+) with [^\s]+ = (.*)/)
    flash[:error] = "No such #{m[1].downcase} '#{m[2]}'"
    create_error(membership)
  end

  def destroy
    if params[:id] == "all"
      content.content_memberships.destroy_all
    else
      content.content_memberships.find(params[:id]).destroy
    end
    redirect_to(redirect_options)
  end

  helper_method :memberships_path
  helper_method :membership_path
  helper_method :new_membership_path
  helper_method :content_path
  helper_method :content

  protected
  def redirect_options
    { :action => "index" }
  end

  def member(user, group)
    return User.find_by_login!(user[:login]) if user && !user[:login].empty?
    return Team.find_by_name!(group[:name]) if group && !group[:name].empty?
    content.owner
  end
end
