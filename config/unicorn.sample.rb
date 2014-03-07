# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

# Unicorn configuration template, start your server like so:
# <app_root>/bin/unicorn -c config/unicorn.sample.rb
#
# This will load a master Unicorn process listening on a UNIX socket
# in $RAILS_ROOT/tmp/pids/unicorn.sock By default the master process
# will have 4 (development mode) or 16 (production mode) workers
#
# Any worker not responding properly within 30 seconds will be killed

require "pathname"
require "yaml"
RAILS_ENV = ENV["RAILS_ENV"] || "production"
RAILS_ROOT = (Pathname(__FILE__) + "../../").realpath.to_s
Socket = (Pathname(RAILS_ROOT) + "tmp/pids/unicorn.sock").to_s
Timeout = 30


worker_processes (RAILS_ENV == "production" ? 16 : 4)
preload_app true

# REE has a copy-on-write friendly GC, enable it if possible
GC.respond_to?(:copy_on_write_friendly?) and GC.copy_on_write_friendly = true
timeout Timeout


listen Socket.to_s

before_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end
end
