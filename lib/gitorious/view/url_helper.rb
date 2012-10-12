# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
  module View
    module UrlHelper
      def project_url(project)
        "/#{project.slug}"
      end

      def repository_url(repository)
        "/#{repository_url_slug(repository)}"
      end

      def repository_url_slug(repository)
        "#{repository.project.slug}/#{repository.name}"
      end

      def download_ref_url(repository, ref)
        "/#{repository_url_slug(repository)}/archive-tarball/#{ref}"
      end

      def watch_url(thing)
        "/favorites?watchable_id=#{thing.id}&watchable_type=#{thing.class}"
      end

      def clone_repository_url(repository)
        "/#{repository_url_slug(repository)}/clone"
      end

      def git_clone_url(repository)
        repository.git_clone_url
      end

      def http_clone_url(repository)
        repository.http_clone_url
      end

      def ssh_clone_url(repository)
        repository.ssh_clone_url
      end

      def default_clone_url(repository)
        repository.default_clone_url
      end

      def readme_url(repository_slug, ref)
        "/#{repository_slug}/readme/#{ref}"
      end

      def repository_activities_url(repository_slug, ref)
        "/#{repository_slug}/activities/#{ref}"
      end

      def commits_url(repository_slug, ref)
        "/#{repository_slug}/commits/#{ref}"
      end

      def merge_requests_url(repository_slug)
        "/#{repository_slug}/merge_requests"
      end

      def repository_community_url(repository_slug)
        "/#{repository_slug}/community"
      end

      def tree_url(repository_slug, ref, path = "")
        "/#{repository_slug}/source/#{ref}:#{path}"
      end

      def blob_url(repository_slug, ref, path)
        "/#{repository_slug}/source/#{ref}:#{path}"
      end

      def blame_url(repository_slug, ref, path)
        "/#{repository_slug}/blame/#{ref}:#{path}"
      end

      def history_url(repository_slug, ref, path)
        "/#{repository_slug}/history/#{ref}:#{path}"
      end

      def raw_url(repository_slug, ref, path)
        "/#{repository_slug}/raw/#{ref}:#{path}"
      end

      def tree_history_url(repository_slug, ref, path)
        "/#{repository_slug}/tree_history/#{ref}:#{path}"
      end
    end
  end
end
