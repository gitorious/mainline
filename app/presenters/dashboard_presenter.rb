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

class DashboardPresenter
  attr_reader :dashboard, :authorizer, :routes

  def initialize(dashboard, authorizer, routes)
    @dashboard = dashboard
    @authorizer = authorizer
    @routes = routes
  end

  def events(starting_page)
    authorizer.filter_paginated(starting_page, Event.per_page) do |page|
      dashboard.events(page)
    end
  end

  def user
    dashboard.user
  end

  def projects
    authorizer.filter(dashboard.projects)
  end

  def repositories
    authorizer.filter(dashboard.repositories)
  end

  def atom_auto_discovery_url
    routes.user_watchlist_path(user, :format => :atom)
  end

  def favorites
    authorizer.filter(dashboard.favorites)
  end

  def user_events(starting_page)
    authorizer.filter_paginated(starting_page, FeedItem.per_page) do |page|
      dashboard.user_events(page)
    end
  end
end

