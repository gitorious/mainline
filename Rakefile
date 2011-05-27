# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

begin
  $: << File.join(File.expand_path(File.dirname(__FILE__)), "app")
  require 'resque/tasks'
rescue LoadError => err
  # Ignore in case not using Resque
end
