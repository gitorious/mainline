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
require "rugged"
require "virtus"
require "push_spec_parser"
require "gitorious/service_payload_generator"

class TestServiceCommand
  def initialize(hook, user)
    @hook = hook
    @repository = hook.repository
    @user = user
  end

  def execute(repository)
    repo = Rugged::Repository.new(repository.full_repository_path)
    parent = repo.head.target.parent_ids.first
    spec = PushSpecParser.new(parent, repo.head.target.oid, repo.head.name)
    Gitorious::ServicePayloadGenerator.new(repository, spec, user).generate!(hook)
    hook
  end

  def build(params)
    repository
  end

  private
  attr_accessor :repository, :user, :hook
end

class TestService
  include UseCase

  def initialize(app, hook, user)
    add_pre_condition(AdminRequired.new(app, hook.repository, user))
    step(TestServiceCommand.new(hook, user), :validator => ServiceTestValidator)
  end
end
