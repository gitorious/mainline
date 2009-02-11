# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec/rails'
require File.dirname(__FILE__) + "/spec_dsl"

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures'
  config.include AuthenticatedTestHelper
  config.include KeyserSource::SpecDSL
  # config.before :each, :type=>:controller do
  #   controller.use_rails_error_handling!
  # end
  config.mock_with :mocha
  
  # config.after(:each) do
  #   path = File.join(GitoriousConfig["repository_base_path"], "*")
  #   Dir[path].each do |dir|
  #     `rm -rf #{dir}`
  #   end
  # end
  
  config.after(:each) do
    Rails.cache.clear
  end

  # You can declare fixtures for each behaviour like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so here, like so ...
  #
  config.global_fixtures = :all
  
  def repo_path
    File.join(File.dirname(__FILE__), "..", ".git")
  end
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
end
