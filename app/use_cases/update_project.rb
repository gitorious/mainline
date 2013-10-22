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
require "validators/project_validator"

class UpdateProjectParams
  include Virtus.model

  attribute :title, String
  attribute :description, String
  attribute :tag_list, String
  attribute :license, String
  attribute :wiki_enabled, Boolean
  attribute :wiki_permissions, Boolean
  attribute :home_url, String
  attribute :bugtracker_url, String
  attribute :mailinglist_url, String
  attribute :default_merge_request_status_id, Integer
  attribute :merge_request_statuses_attributes, Hash

  def to_hash
    super.reject { |k,v| v.nil? }
  end
end

class UpdateProject
  include UseCase

  def initialize(user, project)
    add_pre_condition(RequiredDependency.new(:user, user))
    add_pre_condition(RequiredDependency.new(:project, project))
    input_class(UpdateProjectParams)
    step(UpdateProjectCommand.new(user, project), :validator => [ProjectValidator, UpdateProjectValidator])
  end
end
