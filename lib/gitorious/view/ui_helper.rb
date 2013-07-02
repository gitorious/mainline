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
require "pathname"

module Gitorious
  module View
    module UIHelper
      def asset_url(asset)
        "/ui3#{asset}"
      end

      def site_logo(site)
        logo = Gitorious::Configuration.group_get(
          ["sites", site.subdomain], "logo_url", "/ui3/images/gitorious2013.png"
          )
        "<img src=\"#{logo}\" alt=\"#{site.title}\" title=\"#{site.title}\">"
      end

      def img_url(url)
        asset_url("/images#{url}")
      end

      def alerts(flash)
        types = {
          :notice => "alert-info",
          :error => "alert-error",
          :success => "alert-success"
        }

        content = flash.inject("") do |html, f|
          msg = f[1] =~ /<strong/ ? f[1] : "<strong>#{f[1]}</strong>"
          "#{html}<div class=\"alert #{types[f[0]]}\">#{msg}</div>".html_safe
        end

        return "" if content == ""
        "<div class=\"gts-notification\"><div class=\"container\">#{content}" +
          "</div></div>".html_safe
      end
    end
  end
end
