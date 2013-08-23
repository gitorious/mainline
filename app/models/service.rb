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
    [WebHook, Sprintly]
  end

  def self.global_services
    find(:all, :conditions => {:repository_id => nil})
  end

  def self.for_type_and_repository(service_type, repository)
    adapter = service_type_adapter(service_type)
    scope = repository.services.where(:service_type => service_type)
    adapter.multiple? ? scope.new : scope.first_or_initialize
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

  def adapter
    @adapter ||= create_adapter
  end

  private

  def self.service_type_adapter(service_type)
    Service.types.each do |type|
      return type if type::service_type == service_type
    end

    raise "Unknown service_type: #{service_type}"
  end

  def create_adapter
    Service.service_type_adapter(service_type).new(data)
  end
end
