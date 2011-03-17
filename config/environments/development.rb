# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.debug_rjs                         = true

# ActionMailer::Base.default_url_options[:protocol] = 'https'
ActionMailer::Base.default_url_options[:host] =
  YAML.load_file(File.join(RAILS_ROOT, "config/gitorious.yml"))[RAILS_ENV]["gitorious_host"]
config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :test
ExceptionNotifier.exception_recipients = YAML.load_file(File.join(RAILS_ROOT,
  "config/gitorious.yml"))["exception_notification_emails"]

config.cache_store = :mem_cache_store, ['localhost:11211'], { 
  :namespace => 'ks1' 
}

# It is no longer required to set
# SslRequirement.disable_ssl_check directly to disable SSL for
# Gitorious. Instead, add use_ssl: false to your gitorious.yml to disable SSL
# completely.
