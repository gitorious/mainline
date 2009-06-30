# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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


require File.dirname(__FILE__) + '/../test_helper'

class MergeRequestVersionTest < ActiveSupport::TestCase
  context 'In general' do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
      @merge_request.stubs(:calculate_merge_base).returns("ffcca0")
      @first_version = @merge_request.create_new_version
    end

    should 'ask the target repository for commits' do
      repo = mock("Tracking git repo")
      repo.expects(:commits_between).with(
        @first_version.merge_base_sha,
        @merge_request.merge_branch_name(@first_version.version)
      ).returns([])
      tracking_repo = mock("Tracking repository")
      tracking_repo.stubs(:git).returns(repo)
      @merge_request.stubs(:tracking_repository).returns(tracking_repo)
      @first_version.stubs(:merge_request).returns(@merge_request)
      result = @first_version.affected_commits
    end
  end
end
