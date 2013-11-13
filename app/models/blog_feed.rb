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

require "rss/2.0"
require "open-uri"
require "time"

class BlogFeed
  def initialize(url, limit = 2)
    @url   = url
    @limit = limit
    @html  = HTMLEntities.new
  end

  def fetch
    items = []
    open(@url) do |http|
      response = http.read
      result = RSS::Parser.parse(response, false)
      result.items.each_with_index do |item, i|
        break if i+1 > @limit
        feed_item = {
          :title => item.title,
          :description => decode(item.description),
          # FIXME: There's some issues with ActiveSupport and RSS both overriding
          # Time#to_s so we waste some cycles pasing twice, until there's a fix
          :date => Time.parse(item.date.to_s),
          :link => item.link
        }
        items << feed_item
      end
    end
    items
  end

  def decode(str)
    @html.decode(str)
  end
end
