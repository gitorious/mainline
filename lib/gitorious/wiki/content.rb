
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



module Gitorious
  module Wiki
    module Content
      
      BRACKETED_WIKI_WORD = /\[\[([A-Za-z0-9_\-]+)\]\]/
      
      def wikize(content)
        content = wiki_link(content)
        # rd = RDiscount.new(content, :smart, :generate_toc)
        rd = MarkupRenderer.new(content, :markdown => [:smart, :generate_toc])
        content = content_tag(:div, rd.to_html, :class => "page-content")
        toc_content = rd.markdown.toc_content
        if !toc_content.blank?
          toc = content_tag(:div, toc_content, :class => "toc")
        else
          toc = ""
        end
        content_tag(:div, toc + sanitize_wiki_content(content), :class => "page wiki-page")
      end
      
      def sanitize_wiki_content(html)
        @worker = ActionView::Base.new
        @worker.sanitize(html, :tags =>%w(table tr td th dl dd dt strong em b i p code pre tt samp kbd var sub 
      sup dfn cite big small address hr br div span h1 h2 h3 h4 h5 h6 ul ol li dt dd abbr 
      acronym a img blockquote del ins), :class => "page wiki-page", :attributes => %w[id href src alt])
      end
      
    end
  end
end










