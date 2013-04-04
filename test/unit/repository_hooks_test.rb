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
require "fileutils"

class RepositoryHooksTest < ActiveSupport::TestCase
  should "create missing symlink" do
    hooks = Pathname("/I/dont/exist")
    FileUtils.expects(:ln_sf).with(File.join(Rails.root, "data/hooks"), "/I/dont/exist")
    RepositoryRoot.stubs(:expand).with(".hooks").returns(hooks)

    RepositoryHooks.create(Rails.root + "data")
  end

  should "create local link" do
    FileUtils.expects(:ln_s).with("../data/hooks", "hooks")
    FileUtils.stubs(:ln_sf)
    RepositoryRoot.stubs(:expand).with(".hooks").returns(Rails.root + "data/hooks")

    RepositoryHooks.create(Rails.root + "app")
  end
end
