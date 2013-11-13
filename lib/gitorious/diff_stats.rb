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
require "grit"

module Gitorious
  class DiffStats
    def self.for(from, to, repo)
      diff = repo.git.native(:diff, {:numstat => true}, from, to)
      fake_commit_diff = "fake_id" + "\n" * 4 + diff
      stats = Grit::CommitStats.list_from_string(repo, fake_commit_diff)
      stats.first.last
    end
  end
end
