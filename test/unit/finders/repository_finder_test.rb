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
require "test_helper"
require "repository_finder"

class RepositoryFinderTest < ActiveSupport::TestCase
  should "find repository by id" do
    repository = repositories(:moes)
    assert_equal repository, RepositoryFinder.new.by_id(repository.id)
  end

  should "find repository by id and project id" do
    repository = repositories(:moes)
    assert_equal repository, RepositoryFinder.new.by_id(repository.id, {
        :project_id => repository.project.id
      })
  end

  should "not find repository by id and wrong project id" do
    repository = repositories(:moes)
    refute_equal repository, RepositoryFinder.new.by_id(repository.id, {
        :project_id => repository.project.id + 1
      })
  end

  should "look up repository committers" do
    repository = repositories(:moes)
    refute_equal 0, RepositoryFinder.new.committers(repository).count
  end
end
