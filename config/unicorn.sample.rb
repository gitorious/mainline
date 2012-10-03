# Unicorn configuration template, start your server like so:
# cd <app_root>
# script/unicorn -c config/unicorn.sample.rb
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
  old_pid = RAILS_ROOT + "/tmp/pids/unicorn.pid.oldbin"
  if File.exists?(old_pid) && server.pid != File.read(old_pid).to_i
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

def gitorious_config(key)
  YAML::load_file(Pathname(RAILS_ROOT) + "config/gitorious.yml")[RAILS_ENV][key]
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection

  begin
    uid, gid = Process.euid, Process.egid
    user = gitorious_config("gitorious_user")
    if user
      group = user
      target_uid = Etc.getpwnam(user).uid
      target_gid = Etc.getgrnam(group).gid
      worker.tmp.chown(target_uid, target_gid)
      if uid != target_uid || gid != target_gid
        Process.initgroups(user, target_gid)
        Process::GID.change_privilege(target_gid)
        Process::UID.change_privilege(target_uid)
      end
    end
  rescue => e
    if RAILS_ENV == 'development'
      STDERR.puts "couldn't change user, oh well"
    else
      raise e
    end
  end
end
