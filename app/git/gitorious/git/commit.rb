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

module Gitorious
  module Git
    class Commit
      def initialize(rugged_commit)
        @rugged_commit = rugged_commit
      end

      def id
        rugged_commit.oid
      end

      def id_abbrev
        id[0...7]
      end

      def changeset
        rugged_commit.diff({}).patch
      end

      def short_message
        rugged_commit.message.lines.first.strip
      end

      def author
        Actor.new(author_hash[:name], author_hash[:email])
      end

      def committer
        Actor.new(committer_hash[:name], committer_hash[:email])
      end

      def time
        rugged_commit.time
      end

      alias_method :committed_date, :time

      private

      attr_reader :rugged_commit

      def author_hash
        rugged_commit.author
      end

      def committer_hash
        rugged_commit.committer
      end

      Actor = Struct.new(:name, :email) do
        def to_s
          name
        end
      end
    end
  end
end
