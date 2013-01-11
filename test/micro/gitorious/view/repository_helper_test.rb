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
require "gitorious/view/repository_helper"
require "ostruct"

class Gitorious::View::RepositoryHelperTest < MiniTest::Spec
  include Gitorious::View::RepositoryHelper

  before do
    @repo = Repository.new(:gitdir => "gitorious/mainline.git")
    @default = "git@gitorious.test:gitorious/mainline.git"
  end

  describe "#remote_link" do
    it "returns blank when there's no backend" do
      assert_equal "", remote_link(@repo, nil, "HTTP", @default)
    end

    it "returns link" do
      link = remote_link(@repo, Gitorious.git_daemon, "Git", @default)
      assert_match /\/gitorious\/mainline\.git/, link
      refute_match /active/, link
    end

    it "returns active link for current remoet" do
      link = remote_link(@repo, Gitorious.ssh_daemon, "SSH", @default)
      assert_match /active/, link
    end
  end
end
