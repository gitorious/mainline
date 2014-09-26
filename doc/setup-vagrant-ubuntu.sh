#!/bin/bash

set -e

# This script will install all the necessary packages and get Gitorious running
# on your local machine for development. It can be run as is, or used as a
# step-by-step guide. It is STRONGLY RECOMMENDED to read through the script
# before running it. If you're already using Ruby, Sphinx (search daemon),
# MySQL, nginx and others, it may do things you don't want.
#
# IMPORTANT: This script/guide is NOT recommended for production setups. For
# production setups, please refer to http://getgitorious.com
#
# This script has been tested on Ubuntu Server 12.10, but should work (out of
# the box, or with minor adjustments) on many systems that use apt/debs for
# package management. If you're unsure, read through it before running it,
# and/or execute individual sections manually instead.
#
# The Gitorious team prefers and recommends chruby for managing various Ruby
# versions, and ruby-install to install them.
# https://github.com/postmodern/chruby
# https://github.com/postmodern/ruby-install
#
# This script installs and setups up ruby-install and chruby. If you want use
# Ruby from yum, or some other Ruby manager (rvm, rbenv) feel free to do so.
# Adjust this script accordingly.

# The Gitorious root is _not_ where you check out the Gitorious source code. In
# order to keep everything in one place, this directory will contain the source
# code in its own sub-directory, and use other sub-directories for repositories
# etc.
GITORIOUS_ROOT=/vagrant
GITORIOUS_USER=vagrant

# Create the required directories
cd $GITORIOUS_ROOT
mkdir -p tmp/repositories tmp/tarball-cache tmp/tarball-work tmp/cache

# Some system packages are required in order to build certain Ruby dependencies
# that uses system libraries.
# NOTE: This guide installs mysql, but Gitorious will also run with Postgresql

#sudo apt-get update
sudo apt-get install -q -y curl git-core make gcc g++ mysql-client mysql-server-5.5 libmysqlclient-dev libxml2-dev libxslt1-dev libonig2 libreadline6-dev libpq-dev libicu-dev make ruby-dev sphinxsearch redis-server git-daemon-sysvinit nginx

# Install Ruby. Skip if you've already done this.
wget -O ruby-install-0.2.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.2.1.tar.gz
tar -xzvf ruby-install-0.2.1.tar.gz
cd ruby-install-0.2.1/
sudo make install
ruby-install ruby 1.9.3-p429
cd ..
rm -fr ruby-install-*

wget -O chruby-0.3.6.tar.gz https://github.com/postmodern/chruby/archive/v0.3.6.tar.gz
tar -xzvf chruby-0.3.6.tar.gz
cd chruby-0.3.6/
sudo make install

echo "source /usr/local/share/chruby/chruby.sh" | sudo tee /etc/profile.d/chruby.sh
source /etc/profile.d/chruby.sh

chruby 1.9.3

echo "source /etc/profile.d/chruby.sh && chruby 1.9.3" >> ~/.bash_profile

# Bundler is the tool used to manage Gitorious' Ruby dependencies.
# http://gembundler.com/
which bundle || gem install bundler
cd $GITORIOUS_ROOT
bundle

# development and production environments. This way you only need one set of
# test-data, and can use the two environments exclusively to test that the
# application behaves correctly with the different settings.
echo "test:
  adapter: mysql2
  database: gitorious_test
  username: root
  password:
  host: localhost
  encoding: utf8

development:
  adapter: mysql2
  database: gitorious
  username: root
  password:
  host: localhost
  encoding: utf8

production:
  adapter: mysql2
  database: gitorious
  username: root
  password:
  host: localhost
  encoding: utf8" > config/database.yml

# Take note: This uses your user as the Gitorious user. That means that
# Gitorious will take ownership (i.e.: destructively write to) your
# ~/.ssh/authorized_keys. In many cases, this is not a worry. If you happen to
# SSH into your box however, this should be done with care. When Gitorious has
# done its thing, you can no longer SSH into this box with your current user.
# Two solutions if this worries you:
#
# 1) Set up a different, dedicated git user. This is a bit of work, and requires
#    gentle handling of file permissions and ownership. This is the way to go in
#    production, but for development, it is a bit of a pain.
# 2) Manually move the authorized_keys file in/out whenever you need to work on
#    Gitorious.
# 3) Manage you own keys in ~/.ssh/authorized_keys2, which Gitorious will not
#    touch. Make sure your sshd is configured to use it (it should be by
#    default).
echo "site_name: My Gitorious
user: $GITORIOUS_USER
scheme: http
host: localhost
port: 3000
repository_base_path: /$GITORIOUS_ROOT/tmp/repositories
archive_cache_dir: /$GITORIOUS_ROOT/tmp/tarball-cache
archive_work_dir: /$GITORIOUS_ROOT/tmp/tarball-work

# Development environment overrides
development:
  host: localhost
  messaging_adapter: sync
  enable_record_throttling: false
  merge_request_diff_timeout: 30
" > config/gitorious.yml

bin/rake db:create:all
bin/rake db:schema:load

# The gitorious script is used when you push/pull over SSH. You could create a
# symlink in /usr/bin, but we'll create a small shim instead. This way you'll be
# able to alter PATH to load another version of Ruby than the one in the default
# path without altering ~git/.bashrc or equivalent.

sudo ln -nfs $GITORIOUS_ROOT/bin/gitorious /usr/bin/gitorious

echo "Now you should be able to run the application in development mode:"
echo "rails server # or just rails s"

# Need to ensure that .ssh exists and has proper permissions
mkdir -p /home/$GITORIOUS_USER/.ssh
touch /home/$GITORIOUS_USER/.ssh/authorized_keys
chmod 0700 /home/$GITORIOUS_USER/.ssh
chmod 0600 /home/$GITORIOUS_USER/.ssh/authorized_keys

# To run in production, you must install Redis for background processing.
echo "Start a Redis instance by running redis-server"
echo "To install Redis as a service, refer to"
echo "http://www.saltwebsites.com/2012/install-redis-245-service-centos-6"

cd $GITORIOUS_ROOT
echo "With the Redis server running, start a Resque worker"
echo "QUEUE=* bundle exec rake resque:work"

echo "With the background processes in order, start the server in production:"
echo "rails server -e production"

# To pull repositories over the git protocol, simply start the git daemon:
echo "Start the git-daemon like so:"
echo "git daemon --listen=0.0.0.0 --port=9418 --export-all --base-path=$GITORIOUS_ROOT/tmp/repositories --verbose --reuseaddr $GITORIOUS_ROOT/tmp/repositories"

# To do Git over HTTP, you need a frontend server, as Gitorious uses X-Accel-Redirect to
# avoid locking up a Rails process while serving (potentially lots of) data to
# the Git client.

echo "WARNING! Don't continue if you already have nginx configured to
do things for you. Continue by manually reading the instructions and
apply as suitable."

sudo sed -i "s/user  nginx/user $GITORIOUS_USER/" /etc/nginx/nginx.conf

echo "upstream rails {
  server localhost:3000;
}

server {
  root $GITORIOUS_ROOT/public;
  try_files \$uri/index.html @app;

  location @app {
    proxy_pass http://rails;
    proxy_set_header Host \$http_host;
    proxy_redirect off;
  }

  listen 80;

  # Handle tarball downloads
  # Gitorious will send a X-Accel-Redirect header like
  # X-Accel-Redirect: /tarballs/project-repo-sha.tar.gz
  # Which should be streamed from $GITORIOUS_ROOT/tmp/tarball-cache/project-repo-sha.tar.gz
  location /tarballs/ {
    internal;
    alias $GITORIOUS_ROOT/tmp/tarballs/;
  }
  # Handle git-over-http requests
  # Gitorious will send a X-Accel-Redirect header like
  # X-Accel-Redirect: /git-http/project/repository.git/info/refs
  # Which should map to $GITORIOUS_ROOT/tmp/repositories/project/repository.git/info/refs
  location /git-http/ {
    internal;
    alias $GITORIOUS_ROOT/tmp/repositories/;
  }
}" > /tmp/nginx-gitorious

sudo mv /tmp/nginx-gitorious /etc/nginx/sites-available/gitorious
sudo ln -s /etc/nginx/sites-available/gitorious /etc/nginx/sites-enabled/gitorious

sudo service nginx restart

bin/rake ts:index

# Finally, create a user for yourself. Be sure to answer yes when asked if the
# user should be an admin. If you want to (manually) test certain features for
# non-admins, just come back and create more users later.
bin/create-user
