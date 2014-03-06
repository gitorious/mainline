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

require 'fast_test_helper'
require 'sample_repo_helpers'
require 'gitorious/git/repository'

module Gitorious
  module Git
    class RepositoryTest < MiniTest::Spec
      include SampleRepoHelpers

      let(:path) { sample_repo_path }
      let(:repository) { Repository.new(path) }

      describe "#branch" do
        it "returns the branch for a given name" do
          branch = repository.branch("master")

          branch.wont_be_nil
          branch.name.must_equal "master"
        end

        it "returns nil for non-existing branches" do
          repository.branch("does-not-exist").must_be_nil
        end
      end

      describe '#push' do
        let(:other_repository_path) { sample_repo_path }
        let(:source_ref) { '20ea396ef7b00bd0bb5589c8da4f3f4d157d4934' }

        it "pushes source ref to target repository as target ref" do
          dest_ref = 'refs/heads/slave'
          refspec = "#{source_ref}:#{dest_ref}"

          repository.push(other_repository_path, refspec)

          resolved_dest_ref = `cd #{other_repository_path} && git rev-parse #{dest_ref}`.strip
          resolved_dest_ref.must_equal(source_ref)
        end

        it 'force-pushes for "+" prefixed refspec' do
          refspec = "+#{source_ref}:refs/heads/master"

          repository.push(other_repository_path, refspec)

          resolved_dest_ref = `cd #{other_repository_path} && git rev-parse master`.strip
          resolved_dest_ref.must_equal(source_ref)
        end

        it "raises PushError with error message" do
          proc { repository.push('/bad/url', 'foo:bar') }.must_raise PushError
        end
      end
    end
  end
end
