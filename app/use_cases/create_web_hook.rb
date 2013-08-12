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
require "validators/web_hook_validator"

class WebHookParams
  include Virtus
  attribute :url, String
  attribute :site_wide, Boolean
end

class CreateWebHookCommand
  def initialize(app, repository, user)
    @app = app
    @repository = repository
    @user = user
  end

  def execute(web_hook)
    web_hook.save!
    web_hook
  end

  def build(params)
    Service::WebHook.build(
      :url => params.url,
      :repository => params.site_wide ? nil : repository,
      :user => user)
  end

  private
  attr_reader :user, :repository
end

class CreateWebHook
  include UseCase

  def initialize(app, repository, user)
    input_class(WebHookParams)
    add_pre_condition(AdminRequired.new(app, repository, user))
    step(CreateWebHookCommand.new(app, repository, user), :validator => WebHookValidator)
  end
end
