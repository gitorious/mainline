#!/bin/sh

# This script will install all the necessary packages and get
# Gitorious running on your local machine for development. It can be
# run as is, or used as a step-by-step guide. It is STRONGLY
# RECOMMENDED to read through the script before running it. If you're
# already using Ruby, Sphinx (search daemon), MySQL, nginx and others,
# it may do things you don't want.
#
# IMPORTANT: This script/guide is NOT recommended for production
# setups. For production setups, please refer to
# http://getgitorious.com
#
# This script has been tested on Ubuntu Server 12.10, but should work
# (out of the box, or with minor adjustments) on many systems that use
# apt/debs for package management. If you're unsure, read through it
# before running it, and/or execute individual sections manually
# instead.
#
# Note that this script installs Ruby from yum. This gives you 1.8.7
# on most systems. While supported, this version of Ruby may produce
# more warnings and the occasional oddity than normal. If you already
# have an existing ruby installation, or prefer tools like rbenv or
# rvm, feel free to use them instead. If doing do, modify this script
# accordingly.

GITORIOUS_ROOT=~/projects/gitorious
GITORIOUS_USER=`whoami`

# If you've obtained this script, then this part has probably already
# been done.
#sudo apt-get install -y git-core
#mkdir -p $GITORIOUS_ROOT
#git clone git://gitorious.org/gitorious/mainline.git gitorious

# Gitorious uses submodules for non-ruby dependencies, such as
# front-end code.
git submodule update --recursive --init

# Create the required directoryes
cd $GITORIOUS_ROOT
mkdir repositories
mkdir tarball-cache
mkdir tarball-work
mkdir -p gitorious/tmp/cache
cd gitorious

# Some system packages are required in order to build certain Ruby
# dependencies that uses system libraries.
sudo apt-get install -y make gcc g++ mysql-client mysql-server libmysqlclient-dev libxml2-dev libxslt1-dev libonig2
sudo service mysqld start

# Install Ruby. Skip if you've already done this.
sudo apt-get install -y ruby ruby-dev rubygems

# RubyGems must be up to date in order for Gitorious to work well
sudo gem update --system

# Download, configure and compile Sphinx, the search engine used by
# Gitorious.
cd /tmp
curl -o sphinx-2.0.6.tar.gz http://sphinxsearch.com/files/sphinx-2.0.6-release.tar.gz
tar xvzf sphinx-2.0.6.tar.gz
cd sphinx-2.0.6-release
./configure
sudo make install

# Bundler is the tool used to manage Gitorious' Ruby dependencies.
# http://gembundler.com/
sudo gem install bundler
cd $GITORIOUS_ROOT/gitorious
sudo bundle install

# With all the dependencies installed, let's configure Gitorious. Feel
# free to change username and password for the database etc.
echo "create database gitorious;
create database gitorious_test;
grant all privileges on gitorious.* to gitorious@localhost identified by 'yourpassword';
grant all privileges on gitorious_test.* to gitorious@localhost;" | mysql -u root

# In a developer setup, it makes sense to use the same database for
# the development and production environments. This way you only need
# one set of test-data, and can use the two environments exclusively
# to test that the application behaves correctly with the different
# settings.
echo "test:
  adapter: mysql2
  database: gitorious_test
  username: gitorious
  password: yourpassword
  host: localhost
  encoding: utf8

development:
  adapter: mysql2
  database: gitorious
  username: gitorious
  password: yourpassword
  host: localhost
  encoding: utf8

production:
  adapter: mysql2
  database: gitorious
  username: gitorious
  password: yourpassword
  host: localhost
  encoding: utf8" > config/database.yml

# Take note: This uses your user as the Gitorious user. That means
# that Gitorious will take ownership (i.e.: destructively write to)
# your ~/.ssh/authorized_keys. In many cases, this is not a worry. If
# you happen to SSH into your box however, this should be done with
# care. When Gitorious has done its thing, you can no longer SSH into
# this box with your current user. Two solutions if this worries you:
#
# 1) Set up a different, dedicated git user. This is a bit of work,
#    and requires gentle handling of file permissions and ownership.
#    This is the way to go in production, but for development, it is
#    a bit of a pain.
# 2) Manually move the authorized_keys file in/out whenever you need
#    to work on Gitorious.
echo "site_name: My Gitorious
user: $GITORIOUS_USER
scheme: http
host: gitorious.local
port: 3000
frontend_server: nginx
client_port: 3000
repository_base_path: /home/$GITORIOUS_USER/projects/gitorious/repositories
archive_cache_dir: /home/$GITORIOUS_USER/projects/gitorious/tarball-cache
archive_work_dir: /home/$GITORIOUS_USER/projects/gitorious/tarball-work

# Development environment overrides
development:
  host: localhost
  messaging_adapter: sync
  enable_record_throttling: false
  merge_request_diff_timeout: 30
" > config/gitorious.yml

# Finally, create a user for yourself. Be sure to answer yes when
# asked if the user should be an admin. If you want to (manually) test
# certain features for non-admins, just come back and create more
# users later.
bin/create-user

# The gitorious script is used when you push/pull over SSH. It needs
# to be on path.
sudo ln -s $GITORIOUS_ROOT/gitorious/bin/gitorious /usr/local/bin/gitorious

echo "Now you should be able to run the application in development mode:"
echo "rails server # or just `rails s`"

# To run in production, you must install Redis for background
# processing.
curl -o redis-2.6.4.tar.gz http://redis.googlecode.com/files/redis-2.6.4.tar.gz
tar xvzf redis-2.6.4.tar.gz
cd redis-2.6.4
make
sudo make install

echo "Start a Redis instance by running redis-server"
echo "To install Redis as a service, refer to"
echo "http://www.saltwebsites.com/2012/install-redis-245-service-centos-6"

cd $GITORIOUS_ROOT/gitorious
echo "With the Redis server running, start a Resque worker"
echo "QUEUE=* bundle exec rake resque:work"

echo "With the background processes in order, start the server in production:"
echo "rails server -e production"

# To pull repositories over the git protocol, simply start the git daemon:
sudo apt-get install git-daemon-run
git daemon --listen=0.0.0.0 --port=9418 --export-all --base-path=$GITORIOUS_ROOT/repositories --verbose --reuseaddr $GITORIOUS_ROOT/repositories

# To do Git over HTTP, you need a frontend server, as Gitorious uses
# Sendfile to avoid locking up a Rails process while serving
# (potentially lots of) data to the Git client.

echo "WARNING! Don't continue if you already have nginx configured to
do things for you. Continue by manually reading the instructions and
apply as suitable."

sudo su
echo "[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/6/x86_64/
gpgcheck=0
enabled=1" > /etc/yum.repos.d/nginx.repo

apt-get install nginx
sed -i "s/user  nginx/user $GITORIOUS_USER/" /etc/nginx/nginx.conf

echo "upstream rails {
  server localhost:3000;
}

server {
  root $GITORIOUS_ROOT/gitorious/public;
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
  # Which should be streamed from $GITORIOUS_ROOT/tarball-cache/project-repo-sha.tar.gz
  location /tarballs/ {
    internal;
    alias $GITORIOUS_ROOT/tarballs/;
  }
  # Handle git-over-http requests
  # Gitorious will send a X-Accel-Redirect header like
  # X-Accel-Redirect: /git-http/project/repository.git/info/refs
  # Which should map to $GITORIOUS_ROOT/repositories/project/repository.git/info/refs
  location /git-http/ {
    internal;
    alias $GITORIOUS_ROOT/repositories/;
  }
}" > /etc/nginx/conf.d/000-gitorious

service nginx restart
