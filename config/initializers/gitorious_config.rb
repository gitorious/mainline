GitoriousConfig = c = YAML::load_file(File.join(Rails.root,"config/gitorious.yml"))[RAILS_ENV]

# make the default be publicly open
GitoriousConfig['public_mode'] = true if GitoriousConfig['public_mode'].nil?
GitoriousConfig["locale"] = "en" if GitoriousConfig["locale"].nil?

# set global locale
I18n.default_locale = GitoriousConfig["locale"]
I18n.locale         = GitoriousConfig["locale"]

require "subdomain_validation"
GitoriousConfig.extend(SubdomainValidation)

if !GitoriousConfig.valid_subdomain?
  Rails.logger.warn "Invalid subdomain name #{GitoriousConfig['gitorious_host']}. Session cookies will not work!"
end
