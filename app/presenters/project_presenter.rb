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

require 'charlatan'

class ProjectPresenter
  include Charlatan.new(:project)
  private :project

  if instance_methods.include?(:to_param)
    undef_method :to_param # thank you AS for adding Object#to_param
  end

  def self.model_name
    Project.model_name
  end

  def name
    title
  end

  def open_merge_request_count
    merge_requests.open.count
  end

  def is_a?(thing)
    thing == Project
  end

  def wiki_repository_name
    wiki_repository.name
  end

  def feature_enabled?(name)
    features.include?(name)
  end

  def owner_to_param_with_prefix
    owner.to_param_with_prefix
  end

  def user_to_param_with_prefix
    user.to_param_with_prefix
  end

  def short_created_at
    project.created_at.to_s(:short)
  end

  def long_created_at
    project.created_at.to_s(:long)
  end
end
