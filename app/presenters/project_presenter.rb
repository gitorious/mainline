# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class ProjectPresenter
  def initialize(project)
    @project = project
  end

  def title; project.title; end
  def name; project.title; end
  def slug; project.slug; end
  def description; project.description; end
  def wiki_enabled?; project.wiki_enabled?; end
  def private?; project.private?; end
  def to_param; project.to_param; end
  def errors; project.errors; end
  def owner_id; project.owner_id; end
  def open_merge_request_count; project.merge_requests.open.count; end
  def is_a?(thing); thing == Project; end
  def new_record?; project.new_record?; end
  def owner; project.owner; end
  def tag_list; project.tag_list; end
  def tags; project.tags; end
  def license; project.license; end
  def wiki_enabled; project.wiki_enabled; end
  def home_url; project.home_url; end
  def mailinglist_url; project.mailinglist_url; end
  def bugtracker_url; project.bugtracker_url; end
  def wiki_permissions; project.wiki_permissions; end
  def wiki_repository_name; project.wiki_repository.name; end
  def user; project.user; end
  def to_key; project.to_key; end

  def owner_to_param_with_prefix
    project.owner.to_param_with_prefix
  end

  def user_to_param_with_prefix
    project.user.to_param_with_prefix
  end

  def owned_by_group?
    project.owned_by_group?
  end

  def short_created_at
    project.created_at.to_s(:short)
  end

  def long_created_at
    project.created_at.to_s(:long)
  end

  def self.model_name
    Project.model_name
  end

  private
  def project; @project; end
end
