# Load a fully functional development environment:
# - a thin server (by default on port 5000)
# - a (simple, ruby-based) STOMP server
# - a poller process
web:           thin start
poller:        bundle exec script/poller run
stompserver:   stompserver
git_daemon:     script/git-daemon run