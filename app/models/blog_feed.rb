require "rss/2.0"
require "open-uri"
require "time"

class BlogFeed
  def initialize(url, limit = 2)
    @url = url
    @limit = limit
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
          :description => item.description,
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
end
