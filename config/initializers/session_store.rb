# Be sure to restart your server when you modify this file.

# We can't use a TLD in domain (e.g. we can't set localhost here)!
domain = gitorious_yaml["gitorious_host"]

if domain =~ /\./
  domain = ".#{domain}"
else
  domain = ""
end

Gitorious::Application.config.session_store :cookie_store, {
  :key => '_gitorious_session',
  :domain => domain,
  :expire_after => 3.weeks
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Gitorious::Application.config.session_store :active_record_store
