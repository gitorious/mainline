require "gitorious/messaging"
require File.join(File.dirname(__FILE__), "gitorious_config") unless defined?(GitoriousConfig)
Gitorious::Messaging.configure(GitoriousConfig) unless Gitorious::Messaging::Consumer.configured?
