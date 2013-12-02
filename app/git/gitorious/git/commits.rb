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

require 'set'

module Gitorious
  module Git
    class Commits
      def self.not_merged_upstream(source_commits, upstream_commits)
        upstream_id_set = Set.new(upstream_commits.map(&:id))
        source_id_set = Set.new(source_commits.map(&:id))
        source_commits = source_commits.reject { |commit| upstream_id_set.include?(commit.id) }
        upstream_commits = upstream_commits.reject { |commit| source_id_set.include?(commit.id) }
        upstream_changeset_set = Set.new(upstream_commits.map(&:changeset))

        source_commits.reject{ |commit| upstream_changeset_set.include?(commit.changeset) }
      end
    end
  end
end
