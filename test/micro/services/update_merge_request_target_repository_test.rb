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

require 'fast_test_helper'
require 'update_merge_request_target_repository'

class UpdateMergeRequestTargetRepositoryTest < MiniTest::Spec

  let(:service) { UpdateMergeRequestTargetRepository.new(git_repository_pusher) }
  let(:git_repository_pusher) { stub('git_repository_pusher') }

  describe '#call' do
    let(:merge_request) { stub('merge_request', source_repository_path: '/source/repo',
                                                target_repository_path: '/target/repo',
                                                ending_commit: 'abc',
                                                ref_name: 'def') }

    it "force pushes from source repo to target repo" do
      git_repository_pusher.expects(:push).
        with('/source/repo', '/target/repo', "+abc:def")

      service.call(merge_request)
    end
  end

end
