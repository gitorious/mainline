if ENV['GITORIOUS_WEB_WORKERS']
  worker_processes ENV['GITORIOUS_WEB_WORKERS'].to_i
else
  worker_processes `cat /proc/cpuinfo | grep "^processor" | wc -l`.to_i * 2
end

working_directory "/usr/src/app"
timeout 60
listen 3000
preload_app true

before_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
    Rails.logger.info('Disconnected from ActiveRecord')
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
    Rails.logger.info('Connected to ActiveRecord')
  end
end
