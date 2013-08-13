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
  include Virtus
  attribute :url, String
  attribute :site_wide, Boolean
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
    Service.new(:user => user, :repository => params.site_wide ? nil : repository,
                :service_type => Service::WebHook.service_type, :data => { :url => params.url })
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
