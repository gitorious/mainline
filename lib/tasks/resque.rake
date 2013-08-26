require "resque/tasks"
require Pathname(__FILE__).join("../../../config/environment.rb").realpath

namespace :resque do
  task :setup => :environment
end
