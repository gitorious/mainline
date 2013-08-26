require "resque/tasks"

namespace :resque do
  task :setup do
    require Pathname(__FILE__).join("../../../config/environment.rb").realpath
  end
end
