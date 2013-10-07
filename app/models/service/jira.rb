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

class Service::Jira < Service::Adapter
  label "Jira"

  attributes :url, :api_version, :username, :password

  validates :username, :password, :url, :api_version, :presence => true

  def name
    self.class.label
  end

  def service_url(issue_id)
    "#{url}/rest/api/#{api_version}/issue/#{issue_id}/transitions"
  end

  def notify(http_client, payload)
    data = Service::Jira::Payload.new(payload)

    return unless data.any?

    http_client.post(
      service_url(data.issue_id),
      :body         => data.to_json,
      :content_type => "application/json",
      :basic_auth   => { :user => username, :password => password }
    )
  end
end
