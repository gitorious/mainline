# This test helper was nicked from jamis' routing_tricks plugin
require 'test/unit'

PLUGIN_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
VENDOR_ROOT = File.expand_path(File.join(PLUGIN_ROOT, "..", ".."))

%w(actionpack activesupport railties).each do |framework|
  path = File.expand_path(File.join(VENDOR_ROOT, "rails", framework, "lib"))
  $LOAD_PATH.unshift path
end

require 'active_support'
require 'action_controller'
require 'action_controller/test_process'

$LOAD_PATH.unshift "#{PLUGIN_ROOT}/lib"
require "#{PLUGIN_ROOT}/init"

class ApplicationController < ActionController::Base
end

class BlogsController < ApplicationController
end

class PostsController < ApplicationController
end
