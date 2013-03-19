# Be sure to restart your server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.18' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

if Gem::VERSION >= "1.3.6"
  module Rails
    class GemDependency
      def requirement
        r = super
        (r == Gem::Requirement.default) ? nil : r
      end
    end
  end
end

Rails::Initializer.run do |config|
  gitorious_yaml = YAML.load_file(File.join(RAILS_ROOT, "config/gitorious.yml"))[RAILS_ENV]
  raise "Your config/gitorious.yml does not have an entry for your current Rails environment. Please consult config/gitorious.sample.yml for instructions." unless gitorious_yaml

  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  config.autoload_paths += %W( #{RAILS_ROOT}/lib/gitorious )

  # Avoid class cache errors like "A copy of Gitorious::XYZ has been removed
  # from the module tree but is still active!"
  config.autoload_once_paths  << File.expand_path("#{RAILS_ROOT}/lib/gitorious")

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'

  # The internationalization framework can be changed to have another default locale (standard is :en) or more load paths.
  # All files from config/locales/*.rb,yml are added automatically.
  # config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  #config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # Please note that observers generated using script/generate observer need to have an _observer suffix
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Activate observers that should always be running
  config.active_record.observers = [
      :user_observer
  ]

  config.after_initialize do
    OAuth::Consumer.class_eval {
      remove_const(:CA_FILE) if const_defined?(:CA_FILE)
    }

    OAuth::Consumer::CA_FILE = nil
    Gitorious::Plugin::post_load
    Grit::Git.git_binary = GitoriousConfig["git_binary"]
    Gitorious::SearchIndex.setup
  end
end
