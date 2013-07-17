# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class RepositoryRootTest < ActiveSupport::TestCase
  context "No roots defined" do
    should "provide the default base path" do
      assert_equal "/tmp/git/repositories", RepositoryRoot.default_base_path
    end
  end

  should "expand a path as a Pathname" do
    path = RepositoryRoot.expand("my/repo.git")
    assert_equal Pathname("/tmp/git/repositories/my/repo.git"), path
  end

  should "find relative path as Pathname" do
    path = RepositoryRoot.expand("my/repo.git")
    assert_equal Pathname("my/repo.git"), RepositoryRoot.relative_path(path)
  end
end
