# Those lines are plugin test settings
ENV['RAILS_ENV'] = 'test'

require File.dirname(__FILE__) + '/../../../../config/environment'
require File.dirname(__FILE__) + '/../lib/localized_templates.rb'
require 'test_help'

FIXTURES_PATH = File.join(File.dirname(__FILE__), 'fixtures')
ActionController::Base.view_paths = FIXTURES_PATH
Rails.public_path = "#{FIXTURES_PATH}/public"

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

I18n.locale = 'en-US'