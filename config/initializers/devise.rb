load File.join(Rails.root, 'config', 'initializers', 'gitorious_config.rb') unless defined? GitoriousConfig
require 'devise/strategies/openid_authenticatable'

Devise.setup do |config|
  config.stretches = 1
  config.pepper = ""
  config.encryptor = :restful_authentication_sha1
  config.remember_for = 2.weeks
  config.cookie_options = {:httponly => true}
  config.cookie_options.merge!(:secure => true) if GitoriousConfig['use_ssl']
  config.warden do |manager|
    manager.default_strategies.unshift :openid_authenticatable
  end
end

# Devise 1.0 only: remove when upgrading to Rails 3
# This is necessary for mapping /login and /logout
Devise.use_default_scope = true
