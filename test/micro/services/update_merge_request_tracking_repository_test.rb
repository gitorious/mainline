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
require 'update_merge_request_tracking_repository'

class UpdateMergeRequestTrackingRepositoryTest < MiniTest::Spec

  let(:service) { UpdateMergeRequestTrackingRepository.new(git_repository_pusher) }
  let(:git_repository_pusher) { stub('git_repository_pusher') }

  describe '#call' do
    let(:merge_request) { stub('merge_request', target_repository_path: '/target/repo',
                                                tracking_repository_path: '/tracking/repo') }

    it "pushes from target repo to tracking repo" do
      merge_request.stubs(:ref_name).with().returns('refs/merge-requests/123')
      merge_request.stubs(:ref_name).with(5).returns('refs/merge-requests/123/5')

      git_repository_pusher.expects(:push).
        with('/target/repo', '/tracking/repo', "refs/merge-requests/123:refs/merge-requests/123/5")

      service.call(merge_request, 5)
    end
  end

end
