# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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
require "gitorious/configuration"
require "gitorious/client"

module Gitorious
  VERSION = "3.0.0"

  def self.scheme
    return @scheme if @scheme && cache?
    @scheme = Gitorious::Configuration.get("use_ssl") ? "https" : "http"
  end

  def self.host
    return @host if @host && cache?
    @host = Gitorious::Configuration.get("host", "localhost")
  end

  def self.port
    return @port if @port && cache?
    @port = Gitorious::Configuration.get("port", 80).to_i
  end

  def self.url(path)
    host_port = host
    host_port << ":#{port}" unless port == 80
    "#{scheme}://#{host_port}#{path.sub(/^\/?/, '/')}"
  end

  def self.client
    return @client if @client && cache?
    host = Gitorious::Configuration.get("client_host", "localhost")
    port = Gitorious::Configuration.get("client_port", "80")
    @client = Gitorious::Client.new(host, port)
  end

  def self.email_sender
    return @email_sender if @email_sender && cache?
    default = "Gitorious <no-reply@#{host}>"
    @email_sender = Gitorious::Configuration.get("email_sender", default)
  end

  private
  def self.cache?
    Rails.env.production?
  end
end
