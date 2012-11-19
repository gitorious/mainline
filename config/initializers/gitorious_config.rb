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

unless defined? GitoriousConfig
  require "gitorious/configuration_loader"
  require "gitorious/messaging"

  env = defined?(Rails) ? Rails.env : "test"
  loader = Gitorious::ConfigurationLoader.new

  if defined?(Rails)
    # Load so configure_singletons will configure them
    require Rails.root + "app/models/repository_root"
    require Rails.root + "app/models/project_license"
    require Rails.root + "app/models/project_proposal"
    require Rails.root + "app/models/team"
  end

  # Wire up the global Gitorious::Configuration singleton with settings
  config = loader.configure_singletons(env)

  # Configure messaging
  default_adapter = env == "test" ? "test" : "resque"
  Gitorious::Messaging.adapter = config.get("messaging_adapter", default_adapter)

  if !config.get("symlinked_mirror_repo_base").nil?
    $stderr.puts <<-MSG
The symlinked_mirror_repo_base setting in config/gitorious.yml is no
longer supported. Please specify this directory by running the
mirror:symlinkedrepos rake task with an environment variable instead.
Remember to update your crontab if you run this task with cron.

Example:
env MIRROR_BASEDIR=/var/www/gitorious/repo-mirror bundle exec rake mirror:symlinkedrepos
    MSG
  end

  # Add additional paths for views
  additional_paths = Array(config.get("additional_view_paths", [])).each do |path|
    path = File.expand_path(path)
    if !File.exists?(path)
      $stderr.puts "WARNING: Additional view path '#{path}' does not exists, skipping"
    end
    Gitorious::Application.paths.app.views.unshift(path)
  end

  # TODO: Port remaining settings

  GitoriousConfig = loader.hash(env)
  GitoriousConfig["is_gitorious_dot_org"] = true if GitoriousConfig["is_gitorious_dot_org"].nil?

  if !GitoriousConfig.key?("additional_footer_links")
    GitoriousConfig["additional_footer_links"] = [["Professional Gitorious Services", "http://gitorious.com/"]]
  end

  GitoriousConfig["terms_of_service_url"] = "http://en.gitorious.org/tos" if GitoriousConfig["terms_of_service_url"].nil?
  GitoriousConfig["privacy_policy_url"] = "http://en.gitorious.org/privacy_policy" if GitoriousConfig["privacy_policy_url"].nil?

  # set default tos/privacy policy urls
  GitoriousConfig["terms_of_service_url"] = "http://en.gitorious.org/tos" if GitoriousConfig["terms_of_service_url"].nil? || GitoriousConfig["terms_of_service_url"] == ""
  GitoriousConfig["privacy_policy_url"] = "http://en.gitorious.org/privacy_policy" if GitoriousConfig["privacy_policy_url"].nil? || GitoriousConfig["privacy_policy_url"] == ""



  if !Gitorious.site.valid_fqdn? && defined?(Rails)
    Rails.logger.warn "Invalid subdomain name #{Gitorious.host}. Session cookies will not work!\n" +
      "See http://gitorious.org/gitorious/pages/ErrorMessages for further explanation"
  end

  GitoriousConfig["site_name"] = GitoriousConfig["site_name"] || "Gitorious"
  GitoriousConfig["discussion_url"] = GitoriousConfig.key?("discussion_url") ? GitoriousConfig["discussion_url"] : "http://groups.google.com/group/gitorious"
  GitoriousConfig["blog_url"] = GitoriousConfig.key?("blog_url") ? GitoriousConfig["blog_url"] : "http://blog.gitorious.org"
end

GitoriousConfig["git_binary"] = GitoriousConfig["git_binary"] || "/usr/bin/env git"
GitoriousConfig["git_version"] = `#{GitoriousConfig['git_binary']} --version`.chomp
