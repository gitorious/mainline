# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
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

require File.expand_path("../boot", __FILE__)
require "rails/all"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Gitorious
  class Application < Rails::Application
    config.autoload_paths += [config.root.join("lib")]
    config.encoding = "utf-8"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # See Rails::Configuration for more options.

    # Skip frameworks you're not going to use. To use Rails without a database
    # you must remove the Active Record framework.
    # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
    config.filter_parameters += [:password, :password_confirmation]

    # Only load the plugins named here, in the order given. By default, all plugins
    # in vendor/plugins are loaded in alphabetical order.
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Add additional load paths for your own custom dirs
    config.autoload_paths << (Rails.root + "lib/gitorious").to_s
    config.autoload_paths << (Rails.root + "app").to_s
    config.autoload_paths << (Rails.root + "finders").to_s
    config.autoload_paths << (Rails.root + "serializers").to_s
    config.autoload_paths << (Rails.root + "app/validators").to_s
    config.autoload_paths << (Rails.root + "app/presenters").to_s
    config.autoload_paths << (Rails.root + "app/renderers").to_s

    # Avoid class cache errors like "A copy of Gitorious::XYZ has been removed
    # from the module tree but is still active!"
    config.autoload_once_paths << (Rails.root + "lib/gitorious").to_s

    # Force all environments to use the same logger level
    # (by default production uses :info, the others :debug)
    # config.log_level = :debug

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
    config.time_zone = "UTC"

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

    config.after_initialize do
      OAuth::Consumer.class_eval {
        remove_const(:CA_FILE) if const_defined?(:CA_FILE)
      }

      OAuth::Consumer::CA_FILE = nil
      Gitorious::Plugin::post_load

      require "gitorious/reservations"
      Rails.application.reload_routes!
      Repository.reserve_names(Gitorious::Reservations.repository_names)

      # Set global locale
      I18n.locale = I18n.default_locale = Gitorious::Configuration.get("locale", "en")

      implementation = Gitorious::Configuration.get("enable_ldap_authorization", false) ? LdapGroup : Group
      Team.group_implementation = implementation
    end

    require 'open_id_authentication'
    OpenIdAuthentication.store = :file
    config.middleware.use OpenIdAuthentication

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.precompile += %w(public_index.css)

    # Don't initialize the app during assets compilation
    config.assets.initialize_on_precompile = false

    I18n.enforce_available_locales = true

    # Append additional view paths
    # NOTE: Full-blown configuration loading happens in initializer so it's
    # necessary to load the config file manually here to get the value of this
    # setting.
    # TODO: Decouple config file loading from "configuration initialization"
    # (see gitorious_config.rb).
    require "gitorious/configuration_reader"
    cfg = Gitorious::ConfigurationReader.read((Rails.root + "config" + "gitorious.yml").to_s)

    # Add additional paths for views
    Array(cfg["additional_view_paths"]).each do |path|
      path = File.expand_path(path)

      if File.exists?(path)
        config.paths['app/views'].unshift(path)
      else
        $stderr.puts "WARNING: Additional view path '#{path}' does not exists, skipping"
      end
    end

    config.after_initialize do
      Gitorious::View.stylesheets.concat(Array(cfg["external_stylesheets"]))
    end
  end
end
