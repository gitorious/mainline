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

class Service < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  serialize :data

  def self.types
    [WebHook]
  end

  def self.global_hooks
    find(:all, :conditions => {:repository_id => nil})
  end

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

  def global?
    repository.nil?
  end

  def params
    @params ||= create_params
  end

  class ServiceAdapter
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_accessor :data

    def initialize(data)
      @data = data.presence || {}
    end

    def self.service_type
      name.split(':').last.underscore
    end
  end

  class WebHook < ServiceAdapter
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

  private

  def create_params
    Service.types.each do |type|
      return type.new(data) if type::service_type == service_type
    end

    raise "Unknown service_type: #{service_type}"
  end
end
