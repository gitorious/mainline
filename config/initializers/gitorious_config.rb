unless defined? GitoriousConfig
  GitoriousConfig = c = YAML::load_file(File.join(Rails.root,"config/gitorious.yml"))[Rails.env]

  # make the default be publicly open
  GitoriousConfig["public_mode"] = true if GitoriousConfig["public_mode"].nil?
  GitoriousConfig["locale"] = "en" if GitoriousConfig["locale"].nil?
  GitoriousConfig["is_gitorious_dot_org"] = true if GitoriousConfig["is_gitorious_dot_org"].nil?
  GitoriousConfig["gitorious_support_email"] = "support@gitorious.local" if GitoriousConfig["gitorious_support_email"].nil?

  if !GitoriousConfig.key?("additional_footer_links")
    GitoriousConfig["additional_footer_links"] = [["Professional Gitorious Services", "http://gitorious.com/"]]
  end

  GitoriousConfig["terms_of_service_url"] = "http://en.gitorious.org/tos" if GitoriousConfig["terms_of_service_url"].nil?
  GitoriousConfig["privacy_policy_url"] = "http://en.gitorious.org/privacy_policy" if GitoriousConfig["privacy_policy_url"].nil?
  GitoriousConfig["mangle_email_addresses"] = true if !GitoriousConfig.key?("mangle_email_addresses")

  # require the use of SSL by default
  GitoriousConfig["use_ssl"] = true if GitoriousConfig["use_ssl"].nil?
  GitoriousConfig["scheme"] = GitoriousConfig["use_ssl"] ? "https" : "http"

  # set global locale
  I18n.default_locale = GitoriousConfig["locale"]
  I18n.locale = GitoriousConfig["locale"]

  # set default tos/privacy policy urls
  GitoriousConfig["terms_of_service_url"] = "http://en.gitorious.org/tos" if GitoriousConfig["terms_of_service_url"].blank?
  GitoriousConfig["privacy_policy_url"] = "http://en.gitorious.org/privacy_policy" if GitoriousConfig["privacy_policy_url"].blank?

  require "subdomain_validation"
  GitoriousConfig.extend(SubdomainValidation)

  default_messaging_adapter = Rails.env.test? ? "test" : "stomp"
  GitoriousConfig["messaging_adapter"] ||= default_messaging_adapter

  if !GitoriousConfig.valid_subdomain?
    Rails.logger.warn "Invalid subdomain name #{GitoriousConfig['gitorious_host']}. Session cookies will not work!\n" +
      "See http://gitorious.org/gitorious/pages/ErrorMessages for further explanation"
  end

  if GitoriousConfig.using_reserved_hostname?
    Rails.logger.warn "The specified gitorious_host is reserved in Gitorious\n" +
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
      ActionController::Base.view_paths.unshift(File.expand_path(GitoriousConfig["additional_view_paths"]))
    end
  end
end

GitoriousConfig["git_binary"] = GitoriousConfig["git_binary"] || "/usr/bin/env git"
GitoriousConfig["git_version"] = `#{GitoriousConfig['git_binary']} --version`.chomp
ActionMailer::Base.default_url_options[:protocol] = GitoriousConfig["scheme"]

GitoriousConfig["group_implementation"] = GitoriousConfig["use_ldap_authorization"] ? "LdapGroup" : "Group"
