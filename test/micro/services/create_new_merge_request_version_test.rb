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
require 'create_new_merge_request_version'

class CreateNewMergeRequestVersionTest < MiniTest::Spec

  let(:service) { CreateNewMergeRequestVersion.new(merge_base_lookup, post_create) }

  let(:merge_base_lookup) { stub('merge_base_lookup') }
  let(:post_create) { -> *args { @post_create_args = args } }

  describe '#call' do
    let(:merge_request) { stub('merge_request', target_repository_path: '/target/repo',
                                                target_branch: 'the-branch',
                                                ref_name: 'refs/merge-requests/1',
                                                create_new_version: merge_request_version) }
    let(:merge_request_version) { stub('merge_request_version', version: 5) }

    before do
      merge_base_lookup.stubs(:merge_base).
        with('/target/repo', 'the-branch', 'refs/merge-requests/1').returns('shashasha')
    end

    it "creates a new version" do
      merge_request.expects(:create_new_version).with('shashasha').
        returns(merge_request_version)

      service.call(merge_request)
    end

    it "calls post_create callback with merge_request and new version number" do
      service.call(merge_request)

      @post_create_args.must_equal([merge_request, 5])
    end
  end

end
