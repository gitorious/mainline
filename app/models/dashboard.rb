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

class Dashboard
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def events(page)
    user.paginated_events_in_watchlist(:page => page)
  end

  def projects
    user.projects.includes(:tags, { :repositories => :project })
  end

  def repositories
    user.committerships.commit_repositories
  end

  def favorites
    user.favorites.all(:include => :watchable).select { |f| f.watchable.list_as_favorite? }
  end

  def user_events(page)
    user.events.excluding_commits.paginate(
      :page => page,
      :order => "events.created_at desc",
      :include => [:user, :project]
    )
  end
end

