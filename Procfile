# Load a fully functional development environment:
# - a thin server (by default on port 5000)
# - a git daemon
web:           thin start
git_daemon:    script/git-daemon run
sphinx:        searchd --pidfile --config config/development.sphinx.conf --nodetach
