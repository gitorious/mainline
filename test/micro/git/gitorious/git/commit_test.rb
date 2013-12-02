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
require 'gitorious/git/branch'

require 'rugged'

module Gitorious
  module Git
    class CommitTest < MiniTest::Spec
      include SampleRepoHelpers

      def lookup_commit(sha)
        Commit.new(repo.lookup(sha))
      end

      describe "#id" do
        let(:repo) { sample_rugged_repo }

        it "is equal to the sha hash" do
          lookup_commit("20ea396").id.must_equal "20ea396ef7b00bd0bb5589c8da4f3f4d157d4934"
        end
      end

      describe "#id_abbrev" do
        let(:repo) { sample_rugged_repo }

        it "is equal to the abbreviated sha hash of length 7" do
          lookup_commit("20ea396ef7b00bd0bb5589c8da4f3f4d157d4934").id_abbrev.must_equal "20ea396"
        end
      end

      describe "#short_message" do
        let(:repo) { sample_rugged_repo('with_long_commit_message') }

        it "is equal to the first line of the commit message" do
          lookup_commit("12ceb842544211b7c56eeb55f6b45827f349e140").short_message.must_equal "First line."
        end
      end

      describe "#changeset" do
        let(:repo) { sample_rugged_repo('with_rebases') }
        let(:original) { lookup_commit("82fd08ade6aa5662856b1a6a9b960af1c9f7226b") }
        let(:cherry_picked) { lookup_commit("1402946025f7dbd377a92d92199cf4a90305bdad") }
        let(:other) { lookup_commit("cf122c88efa59437f80df593af4e062be96debaa") }

        it "has the same changeset if commit diffs are equal" do
          original.changeset.must_equal(cherry_picked.changeset)
        end

        it "has different changeset if commits diffs are different" do
          original.changeset.wont_equal(other.changeset)
        end
      end

      describe "#committer" do
        let(:repo) { sample_rugged_repo }
        let(:commit) { lookup_commit("91c2430892b8f1736d84d3418259317793bb1903") }

        it "has a name of the committer" do
          commit.committer.name.must_equal('Marcin Kulik')
        end

        it "has an email of the committer" do
          commit.committer.email.must_equal('m@ku1ik.com')
        end

        it "returns a name as its string representation" do
          commit.committer.to_s.must_equal('Marcin Kulik')
        end
      end

      describe "#author" do
        let(:repo) { sample_rugged_repo }
        let(:commit) { lookup_commit("91c2430892b8f1736d84d3418259317793bb1903") }

        it "has a name of the author" do
          commit.author.name.must_equal('Paweł Pierzchała')
        end

        it "has an email of the author" do
          commit.author.email.must_equal('pawelpierzchala@gmail.com')
        end

        it "returns a name as its string representation" do
          commit.author.to_s.must_equal('Paweł Pierzchała')
        end
      end

      describe "#time" do
        let(:repo) { sample_rugged_repo }

        it "is equal to the commit time" do
          lookup_commit("20ea396").time.must_equal Time.parse('2013-11-13 16:15:23 +0100')
        end
      end
    end
  end
end
