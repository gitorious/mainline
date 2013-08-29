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
  module SubmoduleUrl
    def self.parsers
      [CurrentGitorious.new, GitoriousOrg.new, GitHub.new, BitBucket.new, GenericParser.new]
    end

    def self.for(submodule)
      url = submodule[:url]
      commit = submodule[:oid]

      parsers.map { |p| p.browse_url(url, commit) }.compact.first
    end

    module Parser
      def browse_url(url, commit)
        mountpoints.each do |mountpoint|
          path = parse_mountpoint(mountpoint, url)
          return generate_url(*path, commit) if path
        end
        return nil
      end

      private

      def parse_mountpoint(mountpoint, url)
        base_url = mountpoint.url("")
        return nil unless url.include?(base_url)
        parts = url.gsub(base_url, '').gsub(/\.git$/, '').split("/")
        return nil unless parts.size == 2
        parts
      end
    end

    class CurrentGitorious
      include Parser

      def mountpoints
        [Gitorious.git_daemon, Gitorious.git_http, Gitorious.ssh_daemon]
      end

      def generate_url(project, repository, commit)
        Gitorious.url("#{project}/#{repository}/source/#{commit}")
      end
    end

    class BitBucket
      include Parser

      def mountpoints
        [HttpMountPoint.new("bitbucket.org", 443, "https"), GitSshMountPoint.new("git", "bitbucket.org")]
      end

      def generate_url(project, repository, commit)
        "https://bitbucket.org/#{project}/#{repository}/src/#{commit}"
      end
    end

    class GitHub
      include Parser

      def mountpoints
        [GitMountPoint.new("github.com"), HttpMountPoint.new("github.com", 443, "https"), GitSshMountPoint.new("git", "github.com")]
      end

      def generate_url(project, repository, commit)
        "https://github.com/#{project}/#{repository}/tree/#{commit}"
      end
    end

    class GitoriousOrg
      include Parser

      def mountpoints
        [GitMountPoint.new("gitorious.org"), HttpMountPoint.new("git.gitorious.org"), GitSshMountPoint.new("git", "gitorious.org")]
      end

      def generate_url(project, repository, commit)
        "https://gitorious.org/#{project}/#{repository}/source/#{commit}"
      end
    end

    class GenericParser
      def browse_url(url, commit)
        url
      end
    end
  end
end
