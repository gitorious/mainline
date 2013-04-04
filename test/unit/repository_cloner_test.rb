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
require "pathname"

class TrackingRepositoryCreationProcessorTest < ActiveSupport::TestCase
  should "clone repository and return path to clone" do
    GitBackend.expects(:clone).with("/tmp/git/repositories/dest", "/tmp/git/repositories/source")
    path = RepositoryCloner.clone("source", "dest")

    assert_equal Pathname("/tmp/git/repositories/dest"), path
  end

  should "clone repository and create hooks" do
    GitBackend.expects(:clone).with("/tmp/git/repositories/dest", "/tmp/git/repositories/source")
    RepositoryHooks.expects(:create).with(Pathname("/tmp/git/repositories/dest"))
    path = RepositoryCloner.clone_with_hooks("source", "dest")

    assert_equal Pathname("/tmp/git/repositories/dest"), path
  end
end
