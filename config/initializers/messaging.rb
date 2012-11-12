require "gitorious/messaging"
require File.join(File.dirname(__FILE__), "gitorious_config") unless defined?(GitoriousConfig)
Gitorious::Messaging.configure(Gitorious::Messaging.adapter) unless Gitorious::Messaging::Consumer.configured?
