# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

module Gitorious
  class Reservations
    def self.root_routes
      Rails.application.routes.routes.map do |route|
        path = unformatted(route)
        path == "/" ? nil : path.split("/")[1]
      end.uniq.reject { |r| r.blank? || r.match(/.?:/) }.sort
    end

    def self.public_files
      Dir[Rails.root + "public/*"].inject([]) do |files, f|
        base = File.basename(f)
        files << base
        files << base.sub(/\.html?$/, '') if f.match(/\.html?$/)
        files
      end
    end

    def self.project_routes
      routes = Rails.application.routes.routes.select do |r|
        route = r.path.spec.to_s
        route.match(/^\/:(project_)?id\//) &&
          !route.match(/.+\/:(repository_)?id/)
      end

      routes.map { |route| unformatted(route).split("/")[2] }.uniq.sort
    end

    def self.project_names
      root_routes + public_files
    end

    def self.repository_names
      project_routes
    end

    private
    def self.unformatted(route)
      route.path.spec.to_s.split("(").first
    end
  end
end
