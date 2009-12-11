require "grit/lib/grit"

Grit.log_calls = true
Grit.logger = RAILS_DEFAULT_LOGGER
Grit::Git.git_timeout = 30
