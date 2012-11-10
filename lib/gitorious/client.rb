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
  class Client
    attr_reader :host, :port, :scheme

    def initialize(host, port, scheme = "http")
      @host = host.split(":").first
      @port = port.to_i
      @scheme = scheme
    end

    def url(path)
      host_port = host
      host_port << ":#{port}" unless port == 80
      "#{scheme}://#{host_port}#{path}"
    end
  end
end
