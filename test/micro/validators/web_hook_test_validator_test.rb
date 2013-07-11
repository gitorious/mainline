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
require "validators/web_hook_test_validator"

class WebHookTestValidatorTest < MiniTest::Shoulda
  should "require a commit" do
    repository = Repository.new

    def repository.head; nil; end
    result = WebHookTestValidator.call(repository)

    refute result.valid?
    assert result.errors[:commit]

    def repository.head; raise Grit::NoSuchPathError.new("Oops"); end
    result = WebHookTestValidator.call(repository)

    refute result.valid?
    assert result.errors[:commit]
  end

  should "pass when repository has a commit" do
    repository = Repository.new

    def repository.head
      head = Object.new
      def head.commit; Object.new; end
      head
    end

    def repository.git;
      git = Object.new
      def git.commit(id)
        return Object.new if Object === id
      end
      git
    end

    result = WebHookTestValidator.call(repository)

    assert result.valid?
  end
end
