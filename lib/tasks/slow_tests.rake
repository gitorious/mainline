namespace :test do

  namespace :slow do
    ROTS_PID_FILE = "tmp/pids/rots.pid"
    ROTS_STDOUT_FILE = "tmp/pids/rots.stdout"
    ROTS_STDERR_FILE = "tmp/pids/rots.stderr"
    # TODO: use spawn or popen3 in Ruby 1.9

    def start
      File.open(ROTS_PID_FILE, 'w'){|f| f.write fork{exec "rots > #{ROTS_STDOUT_FILE} 2>#{ROTS_STDERR_FILE}"}}
      sleep 0.1 while !(File.exists?(ROTS_STDERR_FILE) && IO.read(ROTS_STDERR_FILE) =~ /port=1123/)
    end

    def stop
      Process.kill "INT", IO.read(ROTS_PID_FILE).to_i
      File.delete ROTS_PID_FILE, ROTS_STDOUT_FILE, ROTS_STDERR_FILE
    end

    desc "Start ROTS server"
    task :start do
      if File.exists? ROTS_PID_FILE
        puts "Rots is already running. If it is not, please, manually remove #{ROTS_PID_FILE}."
        exit 1
      end
      start
    end

    desc "Stop ROTS server"
    task :stop do
      if !File.exists? ROTS_PID_FILE
        puts "Rots is not running or was not started with rake test:slow:start. #{ROTS_PID_FILE} does not exist."
        exit 1
      end
      stop
    end

    desc "Run slow integration tests"
    task :run do
      if !(already_running = File.exists? ROTS_PID_FILE)
        puts "Rots is not running. Consider running it before the tests if you want faster results ('rake test:slow:start')."
        start
      end
      command = "ruby -Itest -Ilib test/slow/*.rb"
      #system 'ruby', '-Itest', '-Ilib', *Dir['test/slow/*.rb']
      puts command
      system command
      stop unless already_running
    end
  end

end
