require "ci/reporter/rake/minitest"

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

load File.expand_path("../../Rakefile", __FILE__)
