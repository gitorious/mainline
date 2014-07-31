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
require "presenters/project_presenter"

# The presenter is intended to decouple the view and the model. This will enable
# us to refactor the underlying model without changing any views, remove view
# specific logic from the model, and provide a clear, explicit contract between
# the view and the model.
class RepositoryPresenter
  attr_reader :repository
  private :repository

  def self.load(collection)
    collection.map { |repository| RepositoryPresenter.new(repository) }
  end

  def initialize(repository)
    @repository = repository
  end

  def git; repository.git; end
  def id; repository.id; end
  def name; repository.name; end
  def gitdir; repository.gitdir; end
  def real_gitdir; repository.real_gitdir; end
  def to_param; repository.to_param; end
  def path_segment; repository.path_segment; end
  def full_repository_path; repository.full_repository_path; end
  def head_candidate_name; repository.head_candidate_name; end
  def disk_usage; repository.disk_usage; end
  def ready?; repository.ready?; end
  def committerships; repository.committerships.all; end
  def has_commits?; repository.has_commits?; end
  def owner; repository.owner; end
  def user; repository.user; end
  def private?; repository.private?; end
  def public?; repository.public?; end
  def errors; repository.errors; end
  def description; repository.description; end
  def head; repository.head; end
  def deny_force_pushing; repository.deny_force_pushing; end
  def merge_requests_enabled; repository.merge_requests_enabled; end
  def owner_id; repository.owner_id; end
  def to_key; repository.to_key; end
  def url_path; repository.url_path; end
  def content_memberships; repository.content_memberships; end
  def parent; repository.parent && RepositoryPresenter.new(repository.parent); end
  def is_a?(thing); thing == Repository; end
  def internal?; repository.internal?; end

  def has_group_clones?
    group_clones.any?
  end

  def has_user_clones?
    user_clones.any?
  end

  def group_clone_count
    group_clones.count
  end

  def user_clone_count
    user_clones.count
  end

  def user_clones
    @user_clones ||= repository.clones.by_users.fresh.map { |repo| self.class.new(repo) }
  end

  def owner_to_param_with_prefix
    repository.owner.to_param_with_prefix
  end

  def user_to_param_with_prefix
    repository.user.to_param_with_prefix
  end

  def owned_by_group?
    repository.owned_by_group?
  end

  def short_created_at
    repository.created_at.to_s(:short)
  end

  def long_created_at
    repository.created_at.to_s(:long)
  end

  def user_committers
    repository.committerships.users
  end

  def group_committers
    repository.committerships.groups
  end

  def group_clones
    @group_clones ||= repository.clones.by_groups.fresh.map { |repo| self.class.new(repo) }
  end

  def open_merge_request_count
    repository.open_merge_requests.count
  end

  def self.model_name
    Repository.model_name
  end

  def slug
    "#{project.slug}/#{name}"
  end

  def project
    @project ||= ProjectPresenter.new(@repository.project)
  end
end
