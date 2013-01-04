# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2010 Marius Mårnes Mathiesen <marius@shortcut.no>
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
  class MountPoint
    attr_reader :host, :port, :scheme

    def initialize(host, port = nil, scheme = nil)
      @host = host.split(":").first
      @port = (port || default_port).to_i
      @scheme = scheme || default_scheme
    end

    def url(path)
      "#{scheme}://#{host_port}#{path.sub(/^\/?/, '/')}"
    end

    def host_port
      return host if port == default_port
      "#{host}:#{port}"
    end

    # A valid fully qualified domain name is required to contain one
    # dot.
    def valid_fqdn?
      return !host.match(/[a-z0-9_]?\.[a-z0-9_]?/).nil?
    end
  end

  class HttpMountPoint < MountPoint
    def ssl?
      scheme == "https"
    end

    def can_share_cookies?(other_host)
      return false if !valid_fqdn?
      return !other_host.match(Regexp.new("(.+\.)?" + host)).nil?
    end

    def default_scheme
      port == 443 ? "https" : "http"
    end

    def default_port
      scheme == "https" ? 443 : 80
    end
  end

  class GitMountPoint < MountPoint
    def default_scheme; "git"; end
    def default_port; 9418; end
  end

  class GitSshMountPoint < MountPoint
    attr_reader :user

    def initialize(user, host, port = nil)
      @user = user
      super(host, port, "ssh")
    end

    def url(path)
      "#{user}@#{host_port}#{path.sub(/^\/?/, ':')}"
    end

    def default_port; 22; end
  end
end
