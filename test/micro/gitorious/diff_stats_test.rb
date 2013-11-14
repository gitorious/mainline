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
require "sample_repo_helpers"
require "gitorious/diff_stats"

class DiffStatsTests < MiniTest::Spec
  include SampleRepoHelpers

  it 'returns diff stats of all the changed files' do
    from = "b3f9782d5dc0b97b1efcccb1da651af3f646bf4a"
    to = "976587e5dcd6dddebf0bd3b1c51f68853ac8ac64"
    stats = Gitorious::DiffStats.for(from, to, sample_repo)
    assert_equal ['installation.txt', 'readme.txt'], stats.files.map(&:first).sort
  end
end
