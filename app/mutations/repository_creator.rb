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
require "gitorious/authorization"

class RepositoryCreator < Mutations::Command
  include Gitorious::Authorization

  required do
    model :user, :builder => ModelFinder::User
    string :name
    model :project, :builder => ModelFinder::Project
  end

  optional do
    string :description, :empty => true
    boolean :merge_requests_enabled, :default => true
    boolean :private_repository, :default => false
  end

  def execute
    repo = self.class.build(inputs)
    repo.user = user

    unless admin?(user, project.owner)
      add_error(:owner, :authorization, "User is not allowed to create this repository")
      return
    end

    if !repo.save
      messages = repo.errors.full_messages
      repo.errors.each { |k, m| add_error(k, :validation, messages.shift) }
      return
    end

    repo.make_private if Repository.private_on_create?(inputs)
    repo
  end

  def self.build(params)
    params = params.clone
    params.delete(:private_repository)
    project = params.delete(:project)
    repository = project.repositories.new(params)
    repository.kind = Repository::KIND_PROJECT_REPO
    repository.owner = project.owner
    repository.merge_requests_enabled = params[:merge_requests_enabled]
    repository
  end
end
