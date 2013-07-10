# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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
require "gitorious/standalone_resolver"

class StandaloneResolverTest < MiniTest::Spec
  before do
    @project_repo_path = "/project/repository.git"
    @group_repo_path = "/+team/project/repository.git"
    @user_repo_path = "/~user/project/repository.git"
  end

  describe "Resolving paths" do
    it "resolves regular repositories" do
      resolver = Gitorious::StandaloneResolver.new(@group_repo_path)
      assert_equal(["project","repository"], resolver.resolve)
    end

    it "resolves group repositories" do
      resolver = Gitorious::StandaloneResolver.new(@group_repo_path)
      assert_equal(["project","repository"], resolver.resolve)
    end

    it "resolves user repositories" do
      resolver = Gitorious::StandaloneResolver.new(@user_repo_path)
      assert_equal(["project","repository"], resolver.resolve)
    end
  end
end
