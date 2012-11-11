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
require "yaml" if !defined?(YAML)

unless defined? GitoriousConfig
  root = File.join(File.expand_path(File.dirname(__FILE__)), "../..")
  env = defined?(Rails) ? Rails.env : "test"
  global = YAML::load_file(File.join(root,"config/gitorious.yml"))
  config = {
    "production" => global.delete("production"),
    "development" => global.delete("development"),
    "test" => global.delete("test")
  }
  GitoriousConfig = c = config[env]

  # New configuration
  require "gitorious"
  Gitorious::Configuration.append(config[env])
  Gitorious::Configuration.append(global)

  GitoriousConfig["is_gitorious_dot_org"] = true if GitoriousConfig["is_gitorious_dot_org"].nil?

  if !GitoriousConfig.key?("additional_footer_links")
    GitoriousConfig["additional_footer_links"] = [["Professional Gitorious Services", "http://gitorious.com/"]]
  end

  GitoriousConfig["terms_of_service_url"] = "http://en.gitorious.org/tos" if GitoriousConfig["terms_of_service_url"].nil?
  GitoriousConfig["privacy_policy_url"] = "http://en.gitorious.org/privacy_policy" if GitoriousConfig["privacy_policy_url"].nil?
  GitoriousConfig["mangle_email_addresses"] = true if !GitoriousConfig.key?("mangle_email_addresses")

  # set global locale
  if defined?(I18n)
    I18n.default_locale = GitoriousConfig["locale"] || "en"
    I18n.locale = GitoriousConfig["locale"] || "en"
  end

  # set default tos/privacy policy urls
  GitoriousConfig["terms_of_service_url"] = "http://en.gitorious.org/tos" if GitoriousConfig["terms_of_service_url"].nil? || GitoriousConfig["terms_of_service_url"] == ""
  GitoriousConfig["privacy_policy_url"] = "http://en.gitorious.org/privacy_policy" if GitoriousConfig["privacy_policy_url"].nil? || GitoriousConfig["privacy_policy_url"] == ""

  require "subdomain_validation"
  GitoriousConfig.extend(SubdomainValidation)

  default_messaging_adapter = env == "test" ? "test" : "resque"
  GitoriousConfig["messaging_adapter"] ||= default_messaging_adapter

  if !GitoriousConfig.valid_subdomain? && defined?(Rails)
    Rails.logger.warn "Invalid subdomain name #{Gitorious.host}. Session cookies will not work!\n" +
      "See http://gitorious.org/gitorious/pages/ErrorMessages for further explanation"
  end

  GitoriousConfig["site_name"] = GitoriousConfig["site_name"] || "Gitorious"
  GitoriousConfig["discussion_url"] = GitoriousConfig.key?("discussion_url") ? GitoriousConfig["discussion_url"] : "http://groups.google.com/group/gitorious"
  GitoriousConfig["blog_url"] = GitoriousConfig.key?("blog_url") ? GitoriousConfig["blog_url"] : "http://blog.gitorious.org"
  GitoriousConfig["ssh_fingerprint"] = GitoriousConfig["ssh_fingerprint"] || "has not been configured"
  GitoriousConfig["merge_request_diff_timeout"] = (GitoriousConfig["merge_request_diff_timeout"] || 10).to_i

  # Add additional paths for views
  if GitoriousConfig.key?("additional_view_paths")
    path = File.expand_path(GitoriousConfig["additional_view_paths"])

    if !File.exists?(path)
      puts "WARNING: Additional view path '#{path}' does not exists, skipping"
    else
      additional_view_paths = ActionView::PathSet.new([path])
      Gitorious::Application.paths.app.views.unshift(File.expand_path(GitoriousConfig["additional_view_paths"]))
    end
  end

  # Used to be we supported a special git/http subdomain. No longer. The
  # git_http_host setting can be used to emulate the old behavior
  GitoriousConfig["git_http_host"] ||= Gitorious.host
end

GitoriousConfig["git_binary"] = GitoriousConfig["git_binary"] || "/usr/bin/env git"
GitoriousConfig["git_version"] = `#{GitoriousConfig['git_binary']} --version`.chomp
GitoriousConfig["group_implementation"] = GitoriousConfig["use_ldap_authorization"] ? "LdapGroup" : "Group"
