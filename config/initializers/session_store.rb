# Be sure to restart your server when you modify this file.

# We can't use a TLD in domain (e.g. we can't set localhost here)!

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Gitorious::Application.config.session_store :active_record_store

Gitorious::Application.config.session_store(:cookie_store, {
  :key => ENV["GITORIOUS_SESSION_KEY"] || "_gitorious_session",
  :domain => Gitorious.host =~ /\./ ? ".#{Gitorious.host}" : "",
  :httponly => true,
  :secure => Gitorious.ssl?,
  :expire_after => 3.weeks
})
