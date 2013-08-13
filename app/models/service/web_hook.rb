class Service::WebHook < Service::Adapter
  def self.multiple?
    true
  end

  validates_presence_of :url
  validate :valid_url_format

  def url
    data[:url]
  end

  def notify(http_client, payload)
    http_client.post_form(url, :payload => payload.to_json)
  end

  def to_s
    url
  end

  private

  def valid_url_format
    begin
      uri = URI.parse(url)
      errors.add(:url, "must be a valid URL") and return if uri.host.blank?
    rescue URI::InvalidURIError
      errors.add(:url, "must be a valid URL")
    end
  end
end

