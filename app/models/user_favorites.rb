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

class UserFavorites
  def self.favorites(user)
    new(user).favorites
  end

  def initialize(user)
    @user = user
  end

  def favorites
    (projects + repositories + merge_requests).uniq(&:watchable)
  end

  private

  attr_reader :user

  def filter(type, &favorites_generator)
    favorites = user.favorites.includes(:watchable)
    favorites = favorites.select { |f| f.watchable.is_a?(type) }
    favorites += favorites_generator.call.map { |f| Favorite.new(watchable: f) }
    favorites.select { |f| f.watchable.list_as_favorite? }
  end

  def projects
    filter(Project) { user.groups.includes(:projects).flat_map(&:projects) }
  end

  def repositories
    filter(Repository) do
      projects.flat_map { |r| r.watchable.repositories.mainlines } + user.commit_repositories
    end
  end

  def merge_requests
    filter(MergeRequest) { repositories.map(&:watchable).flat_map(&:merge_requests) }
  end
end

