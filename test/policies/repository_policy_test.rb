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
  let(:policy) { RepositoryPolicy.new(user, repository, db_authorization) }
  let(:user) { User.new }
  let(:repository) { Repository.new }
  let(:db_authorization) { stub('db_authorization', can_read_repository?: :yup) }

  describe "#read?" do
    it "delegates to db authorization's #can_read_repository?" do
      assert_equal :yup, policy.read?
    end
  end

  describe "#upload_pack?" do
    it "delegates to db authorization's #can_read_repository?" do
      assert_equal :yup, policy.upload_pack?
    end
  end

  describe "#receive_pack?" do
    it "is false" do
      refute policy.receive_pack?
    end
  end

end
