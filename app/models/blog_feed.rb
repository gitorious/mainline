require "rss/2.0"
require "open-uri"

class BlogFeed
  def initialize(url, limit = 3)
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
          :date => item.date,
          :link => item.link
        }
        items << feed_item
      end
    end
    items
  end
end
