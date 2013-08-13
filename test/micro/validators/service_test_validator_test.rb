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
require "validators/service_test_validator"

class ServiceTestValidatorTest < MiniTest::Spec
  it "requires a commit" do
    repository = Object.new
    Rugged::Repository.stubs(:new).returns(repository)

    def repository.head; nil; end
    result = ServiceTestValidator.call(Repository.new)

    refute result.valid?
    assert result.errors[:repository]

    def repository.head; raise Rugged::ReferenceError.new("Oops"); end
    result = ServiceTestValidator.call(Repository.new)

    refute result.valid?
    assert result.errors[:repository]
  end

  it "passes when repository has a commit" do
    repository = Object.new

    def repository.head
      head = Object.new
      def head.target; "a" * 40; end
      head
    end

    Rugged::Repository.stubs(:new).returns(repository)
    result = ServiceTestValidator.call(Repository.new)

    assert result.valid?
  end
end
