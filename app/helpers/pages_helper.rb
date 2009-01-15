#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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

module PagesHelper
  include CommitsHelper
  
  def wikize(content)
    content = wiki_link(content)
    rd = RDiscount.new(sanitize(content), :smart, :generate_toc)
    content = content_tag(:div, rd.to_html, :class => "page-content")
    toc_content = rd.toc_content
    if !toc_content.blank?
      toc = content_tag(:div, toc_content, :class => "toc")
    else
      toc = ""
    end
    content_tag(:div, toc + content, :class => "page wiki-page")
  end
  
  BRACKETED_WIKI_WORD = /\[\[([A-Za-z0-9_\-]+)\]\]/
  
  def wiki_link(content)
    content.gsub(BRACKETED_WIKI_WORD) do |page_link|
      if bracketed_name = Regexp.last_match.captures.first
        page_link = bracketed_name
      end
      link_to(page_link, project_page_path(@project, page_link), 
                :class => "todo missing_or_existing")
    end
  end
  
  def edit_link(page)
    link_to(t("views.common.edit")+" "+t("views.pages.page"), 
          edit_project_page_path(@project, page.title))
  end
  
  def page_crumbs(page)
    return if page.title == "Home"
    crumbs = %Q{<ul class="page-crumbs">}
    crumbs << %Q{<li>#{link_to("Home", project_page_path(@project, "Home"))} &raquo;</li>}
    crumbs << %Q{<li class="current">#{page.title}</li>}
    crumbs << "</ul>"
  end
  
  def page_node_name(node)
    h(node.name.split(".", 2).first)
  end  
end
