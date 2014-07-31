# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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
  class HttpArchiver
    attr_accessor :url

    def initialize(url)
      @url = url
    end

    def archive(repository, oid, format = 'tar.gz')
      prefix = repository.path_segment.gsub(/\//, "-")
      format = 'tar.gz' if format == 'tgz'
      filename = "#{prefix}-#{oid}.#{format}"

      "#{url}/#{repository.real_gitdir}" +
        "?ref=#{oid}" +
        "&prefix=#{prefix}" +
        "&format=#{format}" +
        "&filename=#{filename}"
    end

  end
end
