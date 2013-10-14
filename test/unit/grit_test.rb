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
require "ostruct"

class GritTest < ActiveSupport::TestCase
  context "diffs" do
    include SampleRepoHelpers

    should "not blow up with non utf8, non ascii files" do
      repo = sample_repo("non_utf8_repo")
      last_commit = repo.head.commit
      diff = last_commit.diffs.first

      string_diff = diff.diff
      utf8_str = "żółć"

      assert (utf8_str + string_diff).include?('foo')
    end
  end
end
