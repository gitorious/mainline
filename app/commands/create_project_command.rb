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
require "virtus"

class NewProjectParams
  include Virtus.model
  attribute :title, String
  attribute :slug, String
  attribute :description, String
  attribute :default_merge_request_status_id, Integer
  attribute :owner_type, String, :default => "User"
  attribute :owner_id, Integer
  attribute :private, Boolean, :default => false
  attribute :license, String
  attribute :home_url, String
  attribute :mailinglist_url, String
  attribute :bugtracker_url, String
  attribute :tag_list, String
  attribute :wiki_enabled, Boolean, :default => true
  attribute :site_id, Integer

  def owner_type
    value = super
    value == 'Group' ? group_implementation_name : value
  end

  private

  def group_implementation_name
    Team.group_implementation.name
  end
end

class CreateProjectCommand
  def initialize(user)
    @user = user.is_a?(Integer) ? User.find(user) : user
  end

  def build(params)
    @private = params.private
    project = Project.new({
        :title           => params.title,
        :slug            => params.slug,
        :description     => params.description,
        :license         => params.license,
        :home_url        => params.home_url,
        :mailinglist_url => params.mailinglist_url,
        :bugtracker_url  => params.bugtracker_url,
        :wiki_enabled    => params.wiki_enabled,
        :tag_list        => params.tag_list
      })
    uid = @user.id
    project.user_id = uid
    project.site_id = params.site_id unless params.site_id.nil?
    project.owner_type = params.owner_type
    project.owner_id = params.owner_type == "User" ? uid : params.owner_id
    project
  end

  def execute(project)
    project.save!
    MergeRequestStatus.create_defaults_for_project(project)
    project.watched_by!(@user)
    project.make_private if Project.private_on_create?(:private => @private)
    project.create_event(Action::CREATE_PROJECT, project, @user)
    project
  end
end
