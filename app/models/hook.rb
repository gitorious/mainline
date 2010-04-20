# encoding: utf-8
#--
#   Copyright (C) 2010 Marius Mathiesen <marius@shortcut.no>
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

class Hook < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  validates_presence_of :repository, :user, :url
  validate :valid_url_format

  def successful_connection(message)
    self.successful_request_count += 1
    self.last_response = message
    save
  end

  def failed_connection(message)
    self.failed_request_count += 1
    self.last_response = message
    save
  end
  
  def valid_url_format
    begin
      uri = URI.parse(url)
      if uri.host.blank?
        errors.add(:url, "must be a valid URL")
      end
      if uri.scheme != "http"
        errors.add(:url, "must be a HTTP URL")
      end
    rescue URI::InvalidURIError
      errors.add(:url, "must be a valid URL")
    end
  end
end
