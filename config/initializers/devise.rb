Devise.setup do |config|
  config.stretches = 1
  config.pepper = ""
  config.encryptor = :restful_authentication_sha1
  config.remember_for = 2.weeks
  # TODO: configure Devise to use secure cookies
end

# Devise 1.0 only: remove when upgrading to Rails 3
# This is necessary for mapping /login and /logout
Devise.use_default_scope = true
