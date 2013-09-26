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
require "use_case"
require "virtus"
require "validators/service_validator"

class ServiceParams
  include Virtus.model
  attribute :data, Hash
  attribute :service_type, String
  attribute :site_wide, Boolean
end

class NullRepository
  def self.services
    Service.scoped
  end
end

class CreateServiceCommand
  def initialize(app, repository, user)
    @app = app
    @repository = repository
    @user = user
  end

  def execute(service)
    service.save!
    service
  end

  def build(params)
    service = Service.for_type_and_repository(params.service_type, params.site_wide ? NullRepository : repository)
    service.user = user
    service.data = params.data
    service
  end

  private
  attr_reader :user, :repository
end

class CreateService
  include UseCase

  def initialize(app, repository, user)
    input_class(ServiceParams)
    add_pre_condition(AdminRequired.new(app, repository, user))
    step(CreateServiceCommand.new(app, repository, user), :validator => ServiceValidator)
  end
end
