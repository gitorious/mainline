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
require "gitorious/view/dolt_helper"
require "gitorious/view/url_helper"
require "gitorious/config"
require "makeup/markup"

module Gitorious
  module View
    module LayoutHelper
      include Gitorious::View::DoltHelper
      include Gitorious::View::UrlHelper
      include Gitorious::Config

      def git_cloning?(repository)
        repository.git_cloning?
      end

      def http_cloning?(repository)
        repository.http_cloning?
      end

      def ssh_cloning?(repository)
        repository.ssh_cloning?
      end

      def repo_url_button(repository, options)
        type = options[:type].downcase
        return "" if !send("#{type}_cloning?".to_sym, repository)

        url = send("#{type}_clone_url".to_sym, repository)
        class_name = (options[:active] ? "active " : "") + "btn gts-repo-url"
        html = "<a class=\"#{class_name}\" href=\"#{url}\">#{options[:type]}</a>"
        return html unless options[:active]

        "#{html}<input class=\"span4 gts-current-repo-url gts-select-onfocus\" " +
          "type=\"url\" value=\"#{url}\">"
      end

      def repo_nav_entries(repository_slug, ref)
        [[:readme, "Readme", readme_url(repository_slug, ref)],
         [:activities, "Activities", repository_activities_url(repository_slug, ref)],
         [:commits, "Commits", commits_url(repository_slug, ref)],
         [:source, "Source", tree_url(repository_slug, ref)],
         [:merge_requests, "Merge requests", merge_requests_url(repository_slug)],
         [:community, "Community", repository_community_url(repository_slug)]]
      end

      def repo_nav(repository, ref, path, options)
        items = options[:entries].map do |entry|
          is_active = entry.first == options[:active]
          <<-HTML
          <li#{" class=\"active\"" if is_active}>
            <a href="#{entry.last}">#{entry[1]}</a>
          </li>
        HTML
        end

        "<ul class=\"nav nav-tabs\">#{items.join}</ul>"
      end

      def favicon_link_tag
        url = favicon_url
        "<link rel=\"shortcut icon\" href=\"#{url}\" type=\"image/x-icon\">"
      end

      def supported_markups
        Makeup::Markup.markups
      end
    end
  end
end
