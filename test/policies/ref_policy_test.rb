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

require "test_helper"

class RefPolicyTest < MiniTest::Spec
  let(:policy) { RefPolicy.new(user, ref) }
  let(:user) { stub('user') }
  let(:ref) { stub('ref', repository: repository, merge_request: merge_request) }
  let(:repository) { stub('repository') }
  let(:merge_request) { nil }

  describe "#create?" do
    describe "when user is nil" do
      let(:user) { nil }

      it "is false" do
        refute policy.create?
      end
    end

    describe "when ref refers to a merge request" do
      let(:merge_request) { stub('merge_request') }

      it "is false" do
        refute policy.create?
      end
    end

    describe "when user is allowed to push to the repository" do
      before do
        RepositoryPolicy.expects(:allowed?).with(user, repository, :push).returns(true)
      end

      it "is true" do
        assert policy.create?
      end
    end

    describe "when user isn't allowed to push to the repository" do
      before do
        RepositoryPolicy.expects(:allowed?).with(user, repository, :push).returns(false)
      end

      it "is false" do
        refute policy.create?
      end
    end
  end

  describe "#update?" do
    let(:ref) { stub('ref', repository: repository, merge_request: nil) }

    describe "when user is nil" do
      let(:user) { nil }

      it "is false" do
        refute policy.update?
      end
    end

    describe "when user is allowed to push to the repository" do
      before do
        RepositoryPolicy.expects(:allowed?).with(user, repository, :push).returns(true)
      end

      it "is true" do
        assert policy.update?
      end
    end

    describe "when user isn't allowed to push to the repository" do
      before do
        RepositoryPolicy.expects(:allowed?).with(user, repository, :push).returns(false)
      end

      it "is false" do
        refute policy.update?
      end
    end

    describe "when ref refers to a merge request" do
      let(:ref) { stub('ref', repository: repository, merge_request: merge_request) }
      let(:merge_request) { stub('merge_request') }

      describe "when user is allowed to update merge request" do
        before do
          RepositoryPolicy.stubs(:allowed?).with(user, repository, :push).returns(false)
          MergeRequestPolicy.expects(:allowed?).with(user, merge_request, :update).returns(true)
        end

        it "is true" do
          assert policy.update?
        end
      end
    end
  end

  describe "#force_update?" do
    let(:ref) { stub('ref', repository: repository, force_update_allowed?: force_update_allowed, merge_request: merge_request) }
    let(:force_update_allowed) { true }
    let(:merge_request) { nil }

    describe "when user is nil" do
      let(:user) { nil }

      it "is false" do
        refute policy.force_update?
      end
    end

    describe "when ref doesn't allow for force updates" do
      let(:force_update_allowed) { false }

      it "is false" do
        refute policy.force_update?
      end
    end

    describe "when user is allowed to push to the repository" do
      before do
        RepositoryPolicy.expects(:allowed?).with(user, repository, :push).returns(true)
      end

      it "is true" do
        assert policy.force_update?
      end
    end

    describe "when user isn't allowed to push to the repository" do
      before do
        RepositoryPolicy.expects(:allowed?).with(user, repository, :push).returns(false)
      end

      it "is false" do
        refute policy.force_update?
      end
    end

    describe "when ref refers to a merge request" do
      let(:merge_request) { stub('merge_request') }

      describe "when user is allowed to update merge request" do
        before do
          RepositoryPolicy.stubs(:allowed?).with(user, repository, :push).returns(false)
          MergeRequestPolicy.expects(:allowed?).with(user, merge_request, :update).returns(true)
        end

        it "is true" do
          assert policy.force_update?
        end
      end
    end
  end

  describe "#delete?" do
    let(:ref) { stub('ref', repository: repository, force_update_allowed?: force_update_allowed, merge_request: merge_request) }
    let(:force_update_allowed) { true }
    let(:merge_request) { nil }

    describe "when user is nil" do
      let(:user) { nil }

      it "is false" do
        refute policy.delete?
      end
    end

    describe "when ref doesn't allow for force updates" do
      let(:force_update_allowed) { false }

      it "is false" do
        refute policy.delete?
      end
    end

    describe "when ref refers to a merge request" do
      let(:merge_request) { stub('merge_request') }

      it "is false" do
        refute policy.delete?
      end
    end

    describe "when user is allowed to push to the repository" do
      before do
        RepositoryPolicy.expects(:allowed?).with(user, repository, :push).returns(true)
      end

      it "is true" do
        assert policy.delete?
      end
    end

    describe "when user isn't allowed to push to the repository" do
      before do
        RepositoryPolicy.expects(:allowed?).with(user, repository, :push).returns(false)
      end

      it "is false" do
        refute policy.delete?
      end
    end
  end

end
