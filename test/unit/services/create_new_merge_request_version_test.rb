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

require 'test_helper'
require 'create_new_merge_request_version'

class CreateNewMergeRequestVersionTest < ActiveSupport::TestCase
  include SampleRepoHelpers

  setup do
    @merge_request = merge_requests(:moes_to_johans_open)
    @merge_request.sequence_number = 5
    @merge_request.source_branch = 'feature1'
    @merge_request.ending_commit = '8a273e1245f73deb8fd9c6055d21d6110cb5f25d'
    @merge_request.save!

    source_repository_path = sample_repo_path
    @merge_request.stubs(:source_repository_path).returns(source_repository_path)
    target_repository_path = sample_repo_path
    @merge_request.stubs(:target_repository_path).returns(target_repository_path)
    @tracking_repository_path = sample_repo_path
    @merge_request.stubs(:tracking_repository_path).returns(@tracking_repository_path)

    UpdateMergeRequestTargetRepository.call(@merge_request)
  end

  should "create a new version" do
    assert_difference '@merge_request.versions.count', 1 do
      CreateNewMergeRequestVersion.call(@merge_request)
    end
  end

  should "push the version to the tracking repository" do
    CreateNewMergeRequestVersion.call(@merge_request)

    mr_ref_sha = `cd #{@tracking_repository_path} && git rev-parse refs/merge-requests/5/1`.strip
    assert_equal '8a273e1245f73deb8fd9c6055d21d6110cb5f25d', mr_ref_sha
  end

end
