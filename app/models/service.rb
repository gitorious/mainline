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
    decorated
  end

  def decorated
    Service.types.each do |type|
      return type.new(self) if type::TYPE == service_type
    end

    raise "Unknown service_type: #{service_type}"
  end

  def self.for_repository(repository)
    where(:repository_id => repository.id)
  end

  class WebHook < SimpleDelegator
    TYPE = "web_hook"

    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    def self.service_type
      TYPE
    end

    def self.multiple?
      true
    end

    def url
      return if data.blank?
      data[:url]
    end

    def url=(value)
      self.data = {} if data.blank?
      data[:url] = value
    end

    def self.build(params = {})
      service = Service.new(params.slice(:user, :repository))
      web_hook = new(service)
      web_hook.url = params[:url]
      web_hook.service_type = TYPE
      web_hook
    end

    def self.create!(params)
      hook = build(params)
      hook.save!
      hook
    end

    def self.find_for_repository(repository, id)
      service = Service.for_repository(repository).where(:service_type => TYPE, :id => id).first!
      service.decorated
    end
  end
end
