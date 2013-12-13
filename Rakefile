# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("../config/application", __FILE__)

begin
  require "ci/reporter/rake/minitest"

  if RUBY_VERSION < "1.9"
    require "rcov/rcovtask"
    Rcov::RcovTask.new do |t|
      t.libs << "test"
      t.libs << "app"
      t.test_files = FileList["test/micro/*_test.rb", "test/micro/**/*_test.rb"]
      t.rcov_opts += %w{--exclude gems,ruby/1.}
    end
  else
    # Compatibility "rcov" task
    # This task moves the simplecov-rcov files into the parent "coverage"
    # directory. This more or less matches what happens when using the rcov gem
    # on Ruby 1.8. This compatibility task allows us to use the same Jenkins
    # configuration on Ruby 1.8 and Ruby > 1.9.
    task :rcov => 'test:micros' do
      puts "Moving simplecov-rcov report to " + File.expand_path( "#{File.dirname(__FILE__)}/coverage" )
      FileUtils.mv("coverage/rcov", ".", :force => true)
      FileUtils.mv("coverage", "simplecov-coverage", :force => true)
      FileUtils.mv("rcov", "coverage", :force => true)
      FileUtils.mv("simplecov-coverage", "coverage/simplecov", :force => true)
    end
  end
rescue LoadError => err
  $stderr.puts "Failed loading some test dependencies: #{err.message}"
end

#require 'airbrake'

Gitorious::Application.load_tasks
