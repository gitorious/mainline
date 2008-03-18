# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# require 'hodel_3000_compliant_logger'
# config.logger = Hodel3000CompliantLogger.new(config.log_path)
config.log_level = :warn

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_extensions   = true

cache_dir = File.expand_path(File.join(RAILS_ROOT, 'public', 'cache'))
config.action_controller.page_cache_directory = cache_dir
config.action_controller.fragment_cache_store = :file_store, File.join(cache_dir, "fragments")

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

ExceptionNotifier.exception_recipients = YAML.load_file(File.join(RAILS_ROOT, 
  "config/gitorious.yml"))["exception_notification_emails"]
ExceptionNotifier.class_eval do 
  remove_method :template_root 
  ExceptionNotifier.template_root = "#{RAILS_ROOT}/vendor/plugins/exception_notification/lib/../views" 
end