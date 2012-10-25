#!/usr/bin/env ruby

# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush

$PROGRAM_NAME="gitorious-poller"

# Load Rails
load File.join(File.expand_path(File.dirname(__FILE__)), "../../..", "config", "environment.rb")

ActiveMessaging::load_processors
ActiveMessaging::start
