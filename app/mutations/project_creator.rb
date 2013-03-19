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
require "mutations"

class ProjectCreator < Mutations::Command
  required do
    string :title
    integer :user_id
    string :slug
    string :description
  end

  optional do
    integer :default_merge_request_status_id, :empty => true
    string :owner_type, :default => "User"
    integer :owner_id
    boolean :private_project, :default => false
    string :license, :empty => true
    string :home_url, :empty => true
    string :mailinglist_url, :empty => true
    string :bugtracker_url, :empty => true
    string :tag_list, :empty => true
    boolean :wiki_enabled
    integer :site_id
  end

  def execute
    project = Project.new(:title => title,
                          :description => description,
                          :slug => slug,
                          :license => license,
                          :home_url => home_url,
                          :mailinglist_url => mailinglist_url,
                          :bugtracker_url => bugtracker_url,
                          :wiki_enabled => wiki_enabled,
                          :tag_list => tag_list)
    project.site_id = site_id unless site_id.nil?
    project.user_id = user_id
    project.owner_type = owner_type
    project.owner_id = owner_type == "User" ? user_id : owner_id

    if !project.save
      messages = project.errors.full_messages
      project.errors.each { |k, m| add_error(k, :validation, messages.shift) }
      return
    end

    project.make_private if Project.private_on_create?(inputs)
    project.create_event(Action::CREATE_PROJECT, project, User.find(user_id))
    project
  end
end
