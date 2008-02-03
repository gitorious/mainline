begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

require File.dirname(__FILE__) + "/../lib/diff-display"

module DiffFixtureHelper
  def load_diff(name)
    File.read(File.dirname(__FILE__) + "/fixtures/#{name}.diff")
  end
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.include DiffFixtureHelper
end