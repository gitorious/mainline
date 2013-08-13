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

class ServiceTypePresenter
  def self.for_services(services, invalid_service = nil)
    Service.types.map{ |type| new(type, services, invalid_service) }
  end

  attr_reader :type, :invalid_service

  def initialize(type, services, invalid_service = nil)
    @type = type
    @services = services
    @invalid_service = invalid_service
  end

  def service_type
    type.service_type
  end

  def template_path
    "/services/#{type.service_type}"
  end

  def params_for_form
    service_for_form.params
  end

  def services
    @services.select{ |s| s.service_type == service_type }.map{ |s| ServiceStatsPresenter.new(s) }
  end

  private

  def service_for_form
    return invalid_service if has_invalid_service?
    Service.new(:service_type => service_type)
  end

  def has_invalid_service?
    invalid_service && invalid_service.service_type == service_type
  end
end
