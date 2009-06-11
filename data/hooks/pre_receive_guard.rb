# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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


require "open-uri"
require 'cgi'

module Gitorious
  module SSH  
    class PreReceiveGuard
      def initialize(query_url, git_spec)
        @query_url  = query_url
        @git_spec   = git_spec
      end

      # extract the target, eg. refs/heads/master
      def git_target
        @git_spec.split(/\s/).last
      end

      def authentication_url
        @query_url << "&git_path=#{CGI.escape(git_target)}"
      end
  
      def allow_push?
        result = get_via_http(authentication_url)
        return result == 'true'
      end
      
      def get_via_http(url)
        open(url).read
      end
    end
  end
end