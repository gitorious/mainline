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

class Service::WebHook < Service::Adapter
  multiple

  label "Web Hooks"

  attributes :url

  validates_presence_of :url
  validate :valid_url_format

  def notify(http_client, payload)
    http_client.post(url, :form_data => {:payload => payload.to_json})
  end

  def name
    url
  end

  def id
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

