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
require "model_finder"

class ProjectCreator < Mutations::Command
  required do
    string :title
    model :user, :builder => ModelFinder::User
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
    project = self.class.build(inputs)

    if !project.save
      messages = project.errors.full_messages
      project.errors.each { |k, m| add_error(k, :validation, messages.shift) }
      return
    end

    project.make_private if Project.private_on_create?(inputs)
    project.create_event(Action::CREATE_PROJECT, project, user)
    project
  end

  def self.build(params)
    project = Project.new({
        :title => params[:title],
        :slug => params[:slug],
        :description => params[:description],
        :license => params[:license],
        :home_url => params[:home_url],
        :mailinglist_url => params[:mailinglist_url],
        :bugtracker_url => params[:bugtracker_url],
        :wiki_enabled => params[:wiki_enabled],
        :tag_list => params[:tag_list]
      })
    uid = params[:user].is_a?(Hash) ? params[:user][:id] : params[:user].id
    project.user_id = uid
    project.site_id = params[:site_id] unless params[:site_id].nil?
    project.owner_type = params[:owner_type]
    project.owner_id = params[:owner_type] == "User" ? uid : params[:owner_id]
    project
  end
end
