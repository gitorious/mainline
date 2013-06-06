# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

module BootstrapHelper
  MAX_PAGES = 16

  def bootstrap_pagination(coll)
    pages = (coll.total_entries / coll.per_page).ceil
    current = coll.current_page
    links = ""
    links = pagination_link("Prev", coll.previous_page, current) if coll.previous_page
    [pages, MAX_PAGES].min.times do |n|
      links << pagination_link(n, n, current)
    end
    if pages > MAX_PAGES
      links << "<li class=\"disabled\"><a>...</a></li>"
      links << pagination_link(pages, pages, current)
    end
    links << pagination_link("Next", coll.next_page, current) if coll.next_page

    <<-HTML.html_safe
      <div class="container">
         <div class="pagination">
           <ul>
             #{links}
           </ul>
        </div>
      </div>
    HTML
  end

  def pagination_link(text, page, current)
    return "<li class=\"active\"><a>#{text}</a></li>" if page == current
    "<li><a href=\"?page=#{page}\">#{text}</a></li>"
  end
end
