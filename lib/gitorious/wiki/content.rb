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
require "action_view"

module Gitorious
  module Wiki
    module Content
      BRACKETED_WIKI_WORD = /\[\[([A-Za-z0-9_\- ]+)\]\]/

      def wikize(content)
        content = content.force_utf8
        [render_toc(content), render_content(content)]
      end

      private

      def render_toc(text)
        renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC)
        renderer.render(text).html_safe
      end

      def render_content(text)
        renderer = Redcarpet::Markdown.new(
          Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true, with_toc_data: true),
          no_intra_emphasis: true,
          autolink: true
        )
        wiki_link(renderer.render(text)).html_safe
      end

    end
  end
end
