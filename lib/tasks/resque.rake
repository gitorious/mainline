require "pathname"

# $: << File.join(File.expand_path(File.dirname(__FILE__)), "app")
require (Pathname(__FILE__) + "../../../config/environment.rb").realpath
require "resque/tasks"
