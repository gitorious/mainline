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
require "gitorious/view/dolt_url_helper"

class Gitorious::View::DoltUrlHelperTest < MiniTest::Spec
  include Gitorious::View::DoltUrlHelper

  describe "#tree_entry_url" do
    it "links to source" do
      assert_equal "/gitorious/source/master:lib/gitorious", tree_entry_url("gitorious", "master", "lib/gitorious")
    end
  end

  describe "#tree_url" do
    it "links to source" do
      assert_equal "/gitorious/source/master:lib/gitorious", tree_url("gitorious", "master", "lib/gitorious")
    end
  end

  describe "#blob_url" do
    it "links to blob" do
      assert_equal "/gitorious/source/master:lib/gitorious.rb", blob_url("gitorious", "master", "lib/gitorious.rb")
    end
  end

  describe "#blame_url" do
    it "links to blame" do
      assert_equal "/gitorious/blame/master:lib/gitorious", blame_url("gitorious", "master", "lib/gitorious")
    end
  end

  describe "#history_url" do
    it "links to history" do
      assert_equal "/gitorious/history/master:lib/gitorious", history_url("gitorious", "master", "lib/gitorious")
    end
  end

  describe "#raw_url" do
    it "links to raw" do
      assert_equal "/gitorious/raw/master:lib/gitorious", raw_url("gitorious", "master", "lib/gitorious")
    end
  end

  describe "#tree_history_url" do
    it "links to tree history" do
      assert_equal "/gitorious/tree_history/master:lib/gitorious", tree_history_url("gitorious", "master", "lib/gitorious")
    end
  end
end
