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
  Configuration.rename("gitorious_host", "host")
  Configuration.rename("gitorious_client_host", "client_host")
  Configuration.rename("gitorious_client_port", "client_port")
  Configuration.rename("sender_email_address", "email_sender")
  Configuration.rename("gitorious_support_email", "support_email")
  Configuration.rename("gitorious_clone_host", "git_daemon_host")
  Configuration.rename("use_ssl", "scheme", <<-EOF) { |use_ssl| use_ssl ? "https" : "http" }
The scheme setting should be set to "http"
or "https".
  EOF
  Configuration.rename("gitorious_user", "user")
  Configuration.rename("repos_and_projects_private_by_default", "projects_default_private", <<-EOF)
Please note that this setting has been
split into two settings:
projects_default_private and repositories_default_private.
  EOF
  Configuration.rename("disable_record_throttling", "enable_record_throttling", <<-EOF) { |d| !d }
You should invert this value.
  EOF
  Configuration.rename("exception_notification_emails", "exception_recipients")
  Configuration.rename("only_site_admins_can_create_projects", "enable_project_approvals")

  Configuration.on_deprecation do |old, new, comment|
    $stderr.puts(<<-EOF)
WARNING! Setting '#{old}' in config/gitorious.yml is deprecated.
Use '#{new}' instead. Many configuration settings have changed
in Gitorious 3, please refer to config/gitorious.sample.yml for full documentation.
#{comment}
    EOF
  end

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

  def self.git_daemon
    return @git_daemon if @git_daemon && cache?
    host = Gitorious::Configuration.get("git_daemon_host") { Gitorious.host }
    port = Gitorious::Configuration.get("git_daemon_port")
    @git_daemon = Gitorious::GitMountPoint.new(host, port)
  end

  def self.ssh_daemon
    return @ssh_daemon if @ssh_daemon && cache?
    host = Gitorious::Configuration.get("ssh_daemon_host") { Gitorious.host }
    @ssh_daemon = Gitorious::GitSshMountPoint.new(Gitorious.user, host)
  end

  def self.git_http
    return @git_http if @git_http && cache?
    host = Gitorious::Configuration.get("git_http_host") { Gitorious.host }
    port = Gitorious::Configuration.get("git_http_port") { Gitorious.port }
    scheme = Gitorious::Configuration.get("git_http_scheme") { Gitorious.scheme }
    @git_http = Gitorious::HttpMountPoint.new(host, port, scheme)
  end

  def self.email_sender
    return @email_sender if @email_sender && cache?
    default = "Gitorious <no-reply@#{host}>"
    @email_sender = Gitorious::Configuration.get("email_sender", default)
  end

  def self.user
    return @user if @user && cache?
    @user = Gitorious::Configuration.get("user", "git")
  end

  def self.public?
    return @public if !@public.nil? && cache?
    @public = Gitorious::Configuration.get("public_mode", true)
  end

  def self.private_repositories?
    return @private_repos if !@private_repos.nil? && cache?
    @private_repos = Gitorious::Configuration.get("enable_private_repositories", false)
  end

  def self.projects_default_private?
    return @projdefpriv if !@projdefpriv.nil? && cache?
    @projdefpriv = private_repositories? && Gitorious::Configuration.get("projects_default_private", false)
  end

  def self.repositories_default_private?
    return @repodefpriv if !@repodefpriv.nil? && cache?
    @repodefpriv = private_repositories? && Gitorious::Configuration.get("repositories_default_private", false)
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

  def self.archive_cache_dir
    return @archive_cache_dir if @archive_cache_dir && cache?
    @archive_cache_dir = Gitorious::Configuration.get("archive_cache_dir")
  end

  def self.archive_work_dir
    return @archive_work_dir if @archive_work_dir && cache?
    @archive_work_dir = Gitorious::Configuration.get("archive_work_dir")
  end

  def self.diff_timeout
    return @diff_timeout if @diff_timeout && cache?
    @diff_timeout = Gitorious::Configuration.get("merge_request_diff_timeout", 10).to_i
  end

  def self.frontend_server
    return @frontend_server if @frontend_server && cache?
    @frontend_server = Gitorious::Configuration.get("frontend_server", "nginx").downcase
  end

  private
  def self.cache?
    return Rails.env.production? if defined?(Rails)
    false
  end
end
