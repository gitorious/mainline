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
require "fast_test_helper"
require "validators/repository_validator"

class RepositoryValidatorTest < MiniTest::Spec
  it "validates presence of required attributes" do
    repository = Repository.new
    result = RepositoryValidator.call(repository)

    refute result.valid?
    refute_nil result.errors[:user_id]
    refute_nil result.errors[:owner_id]
    refute_nil result.errors[:project_id]
    refute_nil result.errors[:name]
  end

  it "ensures unique name" do
    repository = new_repository
    def repository.uniq_name?; false; end
    result = RepositoryValidator.call(repository)

    refute result.valid?
    assert result.errors[:name]
  end

  it "only allows alphanumeric names" do
    repository = new_repository
    validator = RepositoryValidator.new(repository)

    repository.name = "foo bar"
    refute validator.valid?

    repository.name = "foo!bar"
    refute validator.valid?, "valid? it be false"

    repository.name = "foobar"
    assert validator.valid?

    repository.name = "foo42"
    assert validator.valid?
  end

  it "rejects repository with reserved name" do
    Repository.stubs(:reserved_names).returns(["users"])
    repository = new_repository(:name => "users")

    refute RepositoryValidator.call(repository).valid?
  end

  def new_repository(opts = {})
    Repository.new({
        :name => "foo",
        :project_id => 1,
        :user_id => 1,
        :owner_id => 1
      }.merge(opts))
  end
end
