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
  def favorite_button(watchable)
    return "" unless logged_in?
    if logged_in? && favorite = current_user.favorites.detect{|f| f.watchable == watchable}
      link = destroy_favorite_link_to(favorite, watchable)
    else
      link = create_favorite_link_to(watchable)
    end

    content_tag(:div, link, :class => "repository-link favorite button")
  end

  def create_favorite_link_to(watchable)
    link_to("Watch",
            favorites_path(:watchable_id => watchable.id,
                           :watchable_type => watchable.class.name),
            :"data-request-method" => "post",
            :class => "watch-link disabled round-10")
  end

  def destroy_favorite_link_to(favorite, watchable, options = {})
    link_to(options[:label] || "Unwatch", favorite_path(favorite),
            :"data-request-method" => "delete",
            :class => "watch-link enabled round-10")
  end

  def link_to_notification_toggle(favorite)
    link_classes = %w[toggle round-10]
    link_classes << (favorite.notify_by_email? ? "enabled" : "disabled")
    link = link_to(favorite.notify_by_email? ? "on" : "off", favorite,
      :class => link_classes.join(" "))
    content_tag(:div, link,
            :class => "white-button round-10 small-button update favorite")
  end

  def link_to_unwatch_favorite(favorite)
    link = link_to("Unwatch", favorite, :class => "watch-link enabled round-10")
    content_tag(:div, link,
      :class => "white-button round-10 small-button favorite")
  end

  # Builds a link to the target of a favorite event
  def link_to_watchable(watchable)
    case watchable
    when Repository
      link_to(repo_title(watchable, watchable.project),
        repo_owner_path(watchable, [watchable.project, watchable]))
    when MergeRequest
      link_to(h(truncate("##{watchable.to_param}: #{watchable.summary}", :length => 65)),
        repo_owner_path(watchable.target_repository,
          [watchable.source_repository.project,
           watchable.target_repository,
          watchable]))
    else
      link_to(h(watchable.title), watchable)
    end
  end

  # is this +watchable+ included in the users @favorites?
  def favorited?(watchable)
    @favorites.include?(watchable)
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
