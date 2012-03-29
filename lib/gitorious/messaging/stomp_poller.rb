#!/usr/bin/env ruby

# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush

$PROGRAM_NAME="gitorious-poller"

# Load Rails
RAILS_ROOT = File.join(File.expand_path(File.dirname(__FILE__)), "../../..")
load File.join(RAILS_ROOT, 'config', 'environment.rb')

ActiveMessaging::load_processors
ActiveMessaging::start
