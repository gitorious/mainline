require "gitorious/messaging"
require "gitorious_config" unless defined?(GitoriousConfig)
Gitorious::Messaging.configure(GitoriousConfig)
