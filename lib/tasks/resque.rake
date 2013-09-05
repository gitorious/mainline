require "resque/tasks"
require Pathname(__FILE__).join("../../../config/environment.rb").realpath

namespace :resque do
  task :setup => :environment

  desc "Start resque-web server"
  task :web do
    exec "resque-web -L -F -p 5678 config/resque-web.rb"
  end
end
