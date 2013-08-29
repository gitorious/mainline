# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "libdolt"

module Gitorious
  module View
    module DoltUrlHelper
      include ::Dolt::View::MultiRepository

      def archive_url(repository, ref, format)
        repo_url(repository, "/archive/#{ref}.#{format}")
      end

      def tree_entry_url(repository, ref, path = "")
        repo_url(repository, "/source/#{ref}:#{path}")
      end

      alias_method :tree_url, :tree_entry_url
      alias_method :blob_url, :tree_entry_url

      def submodule_url(repository, ref, submodule)
        SubmoduleUrl.for(submodule)
      end

      def blame_url(repository, ref, path)
        repo_url(repository, "/blame/#{ref}:#{path}")
      end

      def history_url(repository, ref, path)
        repo_url(repository, "/history/#{ref}:#{path}")
      end

      def raw_url(repository, ref, path)
        repo_url(repository, "/raw/#{ref}:#{path}")
      end

      def tree_history_url(repository, ref, path)
        repo_url(repository, "/tree_history/#{ref}:#{path}")
      end
    end
  end
end
