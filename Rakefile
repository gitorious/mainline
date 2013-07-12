# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("../config/application", __FILE__)
require "rake"
require "ci/reporter/rake/minitest"

if RUBY_VERSION < "1.9"
  require "rcov/rcovtask"
  Rcov::RcovTask.new do |t|
    t.libs << "test"
    t.libs << "app"
    t.test_files = FileList["test/micro/*_test.rb", "test/micro/**/*_test.rb"]
    t.rcov_opts += %w{--exclude gems,ruby/1.}
  end
end

Gitorious::Application.load_tasks
