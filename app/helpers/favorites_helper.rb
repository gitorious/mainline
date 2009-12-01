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

module FavoritesHelper
  def favorite_link_to(watchable)
    if favorite = current_user.favorites.detect{|f| f.watchable == watchable}
      destroy_favorite_link_to(favorite, watchable)
    else
      create_favorite_link_to(watchable)
    end
  end

  def create_favorite_link_to(watchable)
    class_name = watchable.class.name
    link_to("Start watching this #{class_name.downcase}",
      favorites_path(:watchable_id => watchable.id,:watchable_type => class_name),
      :method => :post, :"data-request-method" => "post", :class => "disabled"
      )
  end

  def destroy_favorite_link_to(favorite, watchable)
    link_to("Stop watching this #{watchable.class.name.downcase}",
      favorite_path(favorite),
      :method => :delete, :"data-request-method" => "delete", :class => "enabled")
  end
end
