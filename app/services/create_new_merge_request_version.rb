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

class CreateNewMergeRequestVersion

  attr_reader :merge_base_lookup, :post_create

  def self.call(merge_request)
    new(Gitorious::Git::Repository, UpdateMergeRequestTrackingRepository).
      call(merge_request)
  end

  def initialize(merge_base_lookup, post_create)
    @merge_base_lookup = merge_base_lookup
    @post_create       = post_create
  end

  def call(merge_request)
    merge_request_version = create_new_version(merge_request)
    post_create.call(merge_request, merge_request_version.version)
  end

  private

  def create_new_version(merge_request)
    merge_base_sha = calculate_merge_base_sha(merge_request)
    merge_request.create_new_version(merge_base_sha)
  end

  def calculate_merge_base_sha(merge_request)
    merge_base_lookup.merge_base(
      merge_request.target_repository_path,
      merge_request.target_branch,
      merge_request.ref_name
    )
  end

end
