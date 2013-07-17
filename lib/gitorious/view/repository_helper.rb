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

module Gitorious
  module View
    module RepositoryHelper
      def remote_link(repository, backend, label, default_remote_url)
        return "" if backend.nil?
        url = backend.url(repository.gitdir)
        class_name = "btn gts-repo-url"
        class_name += " active" if url == default_remote_url
        "<a class=\"#{class_name}\" href=\"#{url}\">#{label}</a>".html_safe
      end

      def refname(ref)
        return ref unless ref.length == 40
        ref[0...7]
      end

      def repository_navigation(items, options = {})
        items.inject("") do |html, item|
          if item[0] == options[:active]
            "#{html}<li class=\"active\"><a>#{item[2]}</a></li>"
          else
            "#{html}<li><a href=\"#{item[1]}\">#{item[2]}</a></li>"
          end
        end.html_safe
      end

      def repository_description(repository)
        render_markup("description.md", repository.description)
      end
    end
  end
end
