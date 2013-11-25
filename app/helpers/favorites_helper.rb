# encoding: utf-8
#--
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

module FavoritesHelper
  def favorite_button(watchable)
    return "" unless logged_in?

    if logged_in? && favorite = current_user.favorites.detect{|f| f.watchable == watchable}
      destroy_favorite_link_to(favorite, watchable)
    else
      create_favorite_link_to(watchable)
    end
  end

  def create_favorite_link_to(watchable)
    url = favorites_path(:watchable_id => watchable.id, :watchable_type => watchable.class.name)
    link_to('<i class="icon icon-star"></i> Watch'.html_safe, url, :method => 'post', :class => 'btn')
  end

  def destroy_favorite_link_to(favorite, watchable, options = {})
    name = options[:label] || '<i class="icon icon-star-empty"></i> Unwatch'.html_safe
    url  = favorite_path(favorite)
    link_to(name, url, :method => 'delete', :class => 'btn')
  end

  def link_to_notification_toggle(favorite)
    link_classes = %w(toggle round-10)
    link_classes << (favorite.notify_by_email? ? "enabled" : "disabled")

    title = favorite.notify_by_email? ? "on" : "off"
    value = favorite.notify_by_email? ? 0 : 1
    url   = favorite_path(favorite)+"?favorite[notify_by_email]=#{value}"

    link_to(title, url, :method => :put)
  end

  def link_to_unwatch_favorite(favorite)
    link_to("Unwatch", favorite, :method => :delete, :class => 'btn')
  end

  # Builds a link to the target of a favorite event
  def link_to_watchable(watchable)
    case watchable
    when Repository
      link_to(repo_title(watchable, watchable.project),
        polymorphic_url([watchable.project, watchable]))
    when MergeRequest
      link_to(h(truncate("##{watchable.to_param}: #{watchable.summary}", :length => 65)),
        polymorphic_url([watchable.source_repository.project,
         watchable.target_repository,
         watchable]))
    else
      link_to(h(watchable.title), polymorphic_url(watchable))
    end
  end

  def css_class_for_watchable(watchable)
    watchable.class.name.underscore
  end

  def css_classes_for(watchable)
    css_classes = ["favorite"]
    css_classes << css_class_for_watchable(watchable)
    if current_user == watchable.user
      css_classes << "mine"
    else
      css_classes << "foreign"
    end
    css_classes.join(" ")
  end
end
