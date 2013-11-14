# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
require "gitorious/app"

class RepositoryActivitiesController < ApplicationController
  before_filter :find_repository_owner
  renders_in_site_specific_context

  def index
    project = authorize_access_to(Project.find_by_slug!(params[:project_id]))
    repository = authorize_access_to(project.repositories.find_by_name!(params[:id]))
    page = JustPaginate.page_value(params[:page])

    events, total_pages = JustPaginate.paginate(page, Event.per_page, repository.events.count) do |index_range|
      repository.events.all(:offset => [index_range.first, 0].max, :limit => index_range.count, :order => "created_at desc")
    end

    respond_to do |format|
      format.html do
        render(:action => :index, :locals => locals(repository, events).merge({
              :ref => repository.head_candidate_name,
              :current_page => page,
              :total_pages => total_pages,
              :atom_auto_discovery_url => activities_project_repository_path(repository.project, repository, :format => :atom),
              :atom_auto_discovery_title => "#{repository.title} ATOM feed"
            }))
      end
      format.xml  { render :xml => repository }
      format.atom { render :action => :index, :locals => locals(repository, events) }
    end
  end

  private
  def locals(repository, events)
    { :repository => RepositoryPresenter.new(repository),
      :events => events }
  end
end
