namespace :gitorious do
  desc "Start Gitorious daemons"
  task :start => 'ultrasphinx:daemon:start' do
    system "/usr/bin/stompserver -w #{RAILS_ROOT}/tmp/stomp -q file -s queue &"
    system "script/poller start"
    system "script/git-daemon"
  end
  
  desc "Stop Gitorious daemons"
  task :stop => 'ultrasphinx:daemon:stop' do
    system "kill `cat log/git-daemon.pid`"
    system "kill `cat #{RAILS_ROOT}/tmp/stomp/log/stompserver.pid`"
    system "kill -9 `cat #{RAILS_ROOT}/tmp/poller/pids/poller0.pid`"
  end
end