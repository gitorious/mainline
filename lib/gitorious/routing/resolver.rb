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
  module Routing
    class Resolver
      attr_reader :uri
      def initialize(uri)
        @uri = uri.sub(/^\//,"")
      end

      def path_segments
        @path_segments ||= uri.split("/")
      end

      def first_path_segment
        path_segments.first
      end

      def contains_slug?
        return false if reserved_uri?
        return true if user_owned_slug?
        return true if team_owned_slug?
        return true if project_identified?
      end

      def project_identified?
        Project.find_by_slug(first_path_segment)
      end

      def project
        slug = if user_owned_slug? || team_owned_slug?
                 path_segments[1]
               else
                 first_path_segment
               end
        Project.find_by_slug(slug)
      end

      def use_default_backend?
        project.on_current_server?
      end
      
      def user_owned_slug?
        (first_path_segment =~ /~.*/) && path_segments.size > 1
      end

      def team_owned_slug?
        (first_path_segment =~ /\+.*/) && path_segments.size > 1
      end

      def reserved_uri?
        Gitorious::Reservations.unaccounted_root_names.include?(first_path_segment)
      end
    end
  end
end
