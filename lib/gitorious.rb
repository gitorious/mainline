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
require "gitorious/configurable"
require "gitorious/mount_point"

module Gitorious
  VERSION = "3.0.0"

  # Application-wide configuration settings.
  Configuration = Configurable.new("GITORIOUS")

  def self.site
    return @site if @site && cache?
    host = Gitorious::Configuration.get("host", "gitorious.local")
    port = Gitorious::Configuration.get("port")
    scheme = Gitorious::Configuration.get("scheme")
    @site = Gitorious::HttpMountPoint.new(host, port, scheme)
  end

  def self.scheme; site.scheme; end
  def self.host; site.host; end
  def self.port; site.port; end
  def self.ssl?; site.ssl?; end
  def self.url(path); site.url(path); end

  def self.client
    return @client if @client && cache?
    host = Gitorious::Configuration.get("client_host", "localhost")
    port = Gitorious::Configuration.get("client_port")
    @client = Gitorious::HttpMountPoint.new(host, port)
  end

  def self.email_sender
    return @email_sender if @email_sender && cache?
    default = "Gitorious <no-reply@#{host}>"
    @email_sender = Gitorious::Configuration.get("email_sender", default)
  end

  def self.public?
    return @public if !@public.nil? && cache?
    @public = Gitorious::Configuration.get("public_mode", true)
  end

  def self.support_email
    return @support_email if @support_email && cache?
    @support_email = Gitorious::Configuration.get("support_email") do
      "gitorious-support@#{host}"
    end
  end

  def self.remote_ops_ips
    return @remote_ops_ips if @remote_ops_ips && cache?
    ips = Gitorious::Configuration.get("remote_ops_ips", ["127.0.0.1"])
    @remote_ops_ips = Array(ips)
  end

  def self.ops?(remote_addr)
    remote_ops_ips.include?(remote_addr)
  end

  private
  def self.cache?
    return Rails.env.production? if defined?(Rails)
    false
  end
end
