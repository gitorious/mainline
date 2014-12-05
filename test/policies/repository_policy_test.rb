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

class RepositoryPolicyTest < MiniTest::Spec
  let(:policy) { RepositoryPolicy.new(user, repository, authorization) }
  let(:user) { User.new }
  let(:repository) { Repository.new }
  let(:authorization) { stub('authorization', can_read_repository?: :yup,
                                              can_push?: :nope) }

  describe "#read?" do
    describe "when user is nil" do
      let(:user) { nil }

      it "is false when public_mode=false" do
        Gitorious::Configuration.override("public_mode" => false) do
          assert_equal false, policy.read?
        end
      end

      it "delegates to authorization's #can_read_repository? when public_mode=true" do
        Gitorious::Configuration.override("public_mode" => true) do
          assert_equal :yup, policy.read?
        end
      end
    end

    describe "when user is present" do
      let(:user) { User.new }

      it "delegates to authorization's #can_read_repository? regardless of public_mode value" do
        Gitorious::Configuration.override("public_mode" => true) do
          assert_equal :yup, policy.read?
        end

        Gitorious::Configuration.override("public_mode" => false) do
          assert_equal :yup, policy.read?
        end
      end
    end
  end

  describe "#push?" do
    it "delegates to authorization's #can_push?" do
      assert_equal :nope, policy.push?
    end
  end

end
