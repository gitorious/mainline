# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

require 'delegate'

class UpdateMergeRequestTrackingRepository < SimpleDelegator

  def initialize(merge_request)
    super(merge_request)
  end

  def call
    raise "No tracking repository exists for merge request #{id}" unless tracking_repository

    refspec = [merge_branch_name, merge_branch_name(next_version_number)].join(":")

    repository = Gitorious::Git::Repository.from_path(target_repository.full_repository_path)
    repository.push(tracking_repository.full_repository_path, refspec)

    create_new_version

    if current_version_number && current_version_number > 1
      target_repository.project.create_event(Action::UPDATE_MERGE_REQUEST, self,
        user, "new version #{current_version_number}")
    end
  end

  private

  def create_new_version
    result = build_new_version
    result.merge_base_sha = calculate_merge_base
    result.save
    return result
  end

  def build_new_version
    versions.build(:version => next_version_number)
  end

  def next_version_number
    highest_version = versions.last
    highest_version_number = highest_version ? highest_version.version : 0
    highest_version_number + 1
  end

  def calculate_merge_base
    target_repository.git.git.merge_base({:timeout => false},
      target_branch, merge_branch_name).strip
  end

end
