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
    module RepositoryHelper
      def remote_link(repository, backend, label, default_remote_url)
        return "" if backend.nil?
        url = backend.url(repository.gitdir)
        class_name = "btn gts-repo-url"
        class_name += " active" if url == default_remote_url
        "<a class=\"#{class_name}\" href=\"#{url}\">#{label}</a>"
      end
    end
  end
end
