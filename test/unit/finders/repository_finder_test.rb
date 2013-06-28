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
  should "find repository by slug" do
    repository = repositories(:moes)
    slug = "#{repository.project.slug}/#{repository.name}"

    assert_equal repository, RepositoryFinder.new.by_slug(slug)
  end

  should "not find repository by slug with wrong project" do
    repository = repositories(:moes)
    slug = "#{repository.project.slug}!!!/#{repository.name}"

    assert_nil RepositoryFinder.new.by_slug(slug)
  end
end
