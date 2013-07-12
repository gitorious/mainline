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
  class MirrorManager
    def initialize(mirrors)
      @mirrors = mirrors
    end

    def init_repository(repository)
      execute_on_mirrors do |mirror|
        "ssh #{mirror} init #{repository.real_gitdir}"
      end
    end

    def clone_repository(src_repository, dst_repository)
      execute_on_mirrors do |mirror|
        "ssh #{mirror} clone #{src_repository.real_gitdir} #{dst_repository.real_gitdir}"
      end
    end

    def delete_repository(path)
      execute_on_mirrors do |mirror|
        "ssh #{mirror} delete #{path}"
      end
    end

    def push(repository)
      execute_on_mirrors do |mirror|
        "git push --gitdir=#{repository.full_repository_path} --mirror #{mirror}:#{repository.real_gitdir}"
      end
    end

    private

    attr_reader :mirrors

    def execute_on_mirrors
      mirrors.each do |mirror|
        Gitorious.executor.run(yield(mirror))
      end
    end
  end
end
