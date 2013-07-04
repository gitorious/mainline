# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("../config/application", __FILE__)
require "rake"

if RUBY_VERSION < "1.9"
  require "ci/reporter/rake/test_unit"
else
  require "ci/reporter/rake/minitest"
end

Gitorious::Application.load_tasks
