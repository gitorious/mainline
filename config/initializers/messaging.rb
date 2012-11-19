require "gitorious/messaging"
require File.join(File.dirname(__FILE__), "gitorious_config") if !defined?(Gitorious) || !Gitorious.configured?
Gitorious::Messaging.configure(Gitorious::Messaging.adapter) unless Gitorious::Messaging::Consumer.configured?
