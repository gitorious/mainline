require "uri"

module UrlLinting
  # Try our best to guess the url
  def clean_url(url)
    return if url.blank?
    begin
      url = "http://#{url}" if URI.parse(url).class == URI::Generic
    rescue
    end
    url.strip
  end
end
