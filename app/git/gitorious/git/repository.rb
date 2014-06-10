# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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

require 'rugged'
require 'open3'
require 'gitorious/git/error'
require 'gitorious/git/branch'

module Gitorious
  module Git
    PushError = Class.new(Error)

    class Repository

      def self.from_path(repository_path)
        new(Rugged::Repository.new(repository_path))
      end

      def self.push(repository_path, dest, refspec)
        from_path(repository_path).push(dest, refspec)
      end

      def self.merge_base(repository_path, sha1, sha2)
        from_path(repository_path).merge_base(sha1, sha2)
      end

      def initialize(rugged_repository)
        @rugged_repository = rugged_repository
      end

      def branch(name)
        branch = rugged_repository.branches[name]
        Branch.new(branch, rugged_repository) if branch
      end

      # NOTE: this method doesn't use native Rugged push because unlike git binary
      # (and thus grit) it doesn't support naked commit sha on the left side of
      # the refspec (and we need that).
      def push(url, refspec)
        cmd = "#{Gitorious.git_binary} push #{url} #{refspec}"

        Open3.popen3(cmd, chdir: rugged_repository.path) do |stdin, stdout, stderr, wait_thr|
          exitcode = wait_thr.value

          if exitcode != 0
            raise PushError.new(stderr.read)
          end
        end
      end

      def merge_base(sha1, sha2)
        rugged_repository.merge_base(sha1, sha2)
      end

      private

      attr_reader :rugged_repository
    end
  end
end
