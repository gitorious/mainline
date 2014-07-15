# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
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
require "pathname"

module Gitorious
  module View
    module UIHelper
      def site_logo(site)
        logo = Gitorious::Configuration.group_get(
          ["sites", site.subdomain], "logo_url", "/dist/images/gitorious2013.png"
          )
        "<img src=\"#{logo}\" alt=\"#{site.title}\" title=\"#{site.title}\">"
      end

      def favicon
        url = Gitorious::Configuration.get("favicon_url", "/favicon.ico")
        "<link rel=\"shortcut icon\" href=\"#{url}\" type=\"image/x-icon\">"
      end

      def system_messages
        system_message = Gitorious::Configuration.get("system_message")

        unless system_message.blank?
          %(<div class="row">
            <p class="system-message"><strong>System notice</strong>: #{system_message.html_safe}</p>
          </div>).html_safe
        end
      end

      def flash_messages
        alerts(defined?(flash) ? flash : {})
      end

      def alerts(flash)
        partial 'layouts/flashes', flash: flash
      end

      def header_navigation(items, options = {})
        items.inject("") do |html, item|
          active_class = item[0] == options[:active] ? " class=\"active\"" : ""
          "#{html}<li#{active_class}><a href=\"#{item[1]}\">#{item[2]}</a></li>"
        end.html_safe
      end

      def description(object, method = :description)
        content = object.public_send(method)
        return '' if content.blank?
        render_markup('description.md', content).html_safe
      end
    end
  end
end
